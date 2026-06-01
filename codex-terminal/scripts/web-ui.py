#!/usr/bin/env python3

import asyncio
import json
import os
import pathlib
import shlex
import time
from typing import Any

from aiohttp import ClientSession, WSMsgType, web


TTYD_UPSTREAM = os.environ.get("TTYD_UPSTREAM", "http://127.0.0.1:7682")
CODEX_HOME = pathlib.Path(os.environ.get("CODEX_HOME", "/data/.codex"))
OPTIONS_FILE = pathlib.Path("/data/options.json")
STARTUP_STATUS_FILE = pathlib.Path("/data/startup-status.log")
CONTEXT_DIR = pathlib.Path("/data/ha-context")


def load_json(path: pathlib.Path, default: Any) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return default


def tail(path: pathlib.Path, lines: int = 80) -> str:
    try:
        data = path.read_text(encoding="utf-8", errors="replace").splitlines()
        return "\n".join(data[-lines:])
    except Exception:
        return ""


async def run_command(*args: str, timeout: int = 120) -> dict[str, Any]:
    started = time.time()
    try:
        proc = await asyncio.create_subprocess_exec(
            *args,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.STDOUT,
        )
        try:
            stdout, _ = await asyncio.wait_for(proc.communicate(), timeout=timeout)
        except asyncio.TimeoutError:
            proc.kill()
            await proc.wait()
            return {
                "ok": False,
                "returncode": -1,
                "output": f"Command timed out after {timeout}s: {shlex.join(args)}",
                "duration_ms": int((time.time() - started) * 1000),
            }
        output = stdout.decode("utf-8", errors="replace")
        return {
            "ok": proc.returncode == 0,
            "returncode": proc.returncode,
            "output": output[-20000:],
            "duration_ms": int((time.time() - started) * 1000),
        }
    except FileNotFoundError as exc:
        return {
            "ok": False,
            "returncode": 127,
            "output": str(exc),
            "duration_ms": int((time.time() - started) * 1000),
        }


async def get_status(_: web.Request) -> web.Response:
    options = load_json(OPTIONS_FILE, {})
    manifest = load_json(CONTEXT_DIR / "manifest.json", {})
    codex_version = await run_command("codex", "--version", timeout=10)
    tmux_status = await run_command("tmux", "has-session", "-t", "codex", timeout=5)

    auth_candidates = [
        CODEX_HOME / "auth.json",
        CODEX_HOME / "config.toml",
        pathlib.Path("/root/.codex/auth.json"),
    ]

    payload = {
        "codex_version": codex_version["output"].strip() if codex_version["ok"] else "unavailable",
        "codex_auth_present": any(path.exists() for path in auth_candidates),
        "tmux_session_active": tmux_status["ok"],
        "options": options,
        "startup_log": tail(STARTUP_STATUS_FILE, 80),
        "context": {
            "agents_md_exists": (CODEX_HOME / "AGENTS.md").exists(),
            "json_context_exists": CONTEXT_DIR.exists(),
            "manifest": manifest,
        },
    }
    return web.json_response(payload)


async def action(request: web.Request) -> web.Response:
    name = request.match_info["name"]
    commands = {
        "doctor": (("codex-ha", "doctor"), 180),
        "refresh-context": (("ha-context", "--force"), 180),
        "check-config": (("ha-safe-edit", "check"), 120),
        "mcp-list": (("codex", "mcp", "list"), 60),
        "list-plans": (("ha-safe-edit", "list-plans"), 30),
    }

    if name not in commands:
        return web.json_response({"ok": False, "output": f"Unknown action: {name}"}, status=404)

    args, timeout = commands[name]
    result = await run_command(*args, timeout=timeout)
    return web.json_response(result)


async def index(_: web.Request) -> web.Response:
    return web.Response(text=HTML, content_type="text/html")


async def terminal_redirect(_: web.Request) -> web.Response:
    raise web.HTTPFound("/terminal/")


async def terminal_proxy(request: web.Request) -> web.StreamResponse:
    tail_path = request.match_info.get("tail", "")
    upstream_path = "/" + tail_path
    if request.query_string:
        upstream_path += "?" + request.query_string
    upstream_url = TTYD_UPSTREAM.rstrip("/") + upstream_path

    if request.headers.get("Upgrade", "").lower() == "websocket":
        return await websocket_proxy(request, upstream_url)

    body = await request.read()
    headers = {k: v for k, v in request.headers.items() if k.lower() not in {"host", "content-length"}}
    async with ClientSession() as session:
        async with session.request(request.method, upstream_url, data=body, headers=headers, allow_redirects=False) as upstream:
            excluded = {"content-encoding", "transfer-encoding", "connection", "content-length"}
            response_headers = {k: v for k, v in upstream.headers.items() if k.lower() not in excluded}
            payload = await upstream.read()
            return web.Response(status=upstream.status, headers=response_headers, body=payload)


async def websocket_proxy(request: web.Request, upstream_url: str) -> web.WebSocketResponse:
    downstream = web.WebSocketResponse()
    await downstream.prepare(request)

    headers = {k: v for k, v in request.headers.items() if k.lower() not in {"host", "connection", "upgrade"}}
    async with ClientSession() as session:
        async with session.ws_connect(upstream_url, headers=headers) as upstream:
            async def client_to_upstream() -> None:
                async for msg in downstream:
                    if msg.type == WSMsgType.TEXT:
                        await upstream.send_str(msg.data)
                    elif msg.type == WSMsgType.BINARY:
                        await upstream.send_bytes(msg.data)
                    elif msg.type == WSMsgType.CLOSE:
                        await upstream.close()

            async def upstream_to_client() -> None:
                async for msg in upstream:
                    if msg.type == WSMsgType.TEXT:
                        await downstream.send_str(msg.data)
                    elif msg.type == WSMsgType.BINARY:
                        await downstream.send_bytes(msg.data)
                    elif msg.type == WSMsgType.CLOSE:
                        await downstream.close()

            tasks = [asyncio.create_task(client_to_upstream()), asyncio.create_task(upstream_to_client())]
            done, pending = await asyncio.wait(tasks, return_when=asyncio.FIRST_COMPLETED)
            for task in pending:
                task.cancel()
            for task in done:
                task.result()

    return downstream


HTML = r"""<!doctype html>
<html lang="ro">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Codex Terminal</title>
  <style>
    :root {
      color-scheme: dark;
      --bg: #111418;
      --panel: #171c22;
      --panel-2: #1f2630;
      --text: #e6edf3;
      --muted: #9aa7b2;
      --accent: #36c2a5;
      --danger: #ff6b6b;
      --border: #2d3642;
      --shadow: rgba(0, 0, 0, .25);
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      background: var(--bg);
      color: var(--text);
      font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      line-height: 1.45;
    }
    header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
      padding: 16px 18px;
      border-bottom: 1px solid var(--border);
      background: #0f1317;
    }
    h1 { margin: 0; font-size: 18px; letter-spacing: 0; }
    main {
      display: grid;
      grid-template-columns: minmax(280px, 360px) minmax(0, 1fr);
      min-height: calc(100vh - 58px);
    }
    aside {
      padding: 14px;
      border-right: 1px solid var(--border);
      background: var(--panel);
      overflow: auto;
    }
    section.terminal {
      min-height: calc(100vh - 58px);
      background: #101418;
    }
    iframe {
      width: 100%;
      height: 100%;
      min-height: calc(100vh - 58px);
      border: 0;
      display: block;
    }
    .status-grid {
      display: grid;
      grid-template-columns: 1fr;
      gap: 8px;
      margin-bottom: 12px;
    }
    .status-row, .panel {
      border: 1px solid var(--border);
      background: var(--panel-2);
      border-radius: 8px;
      box-shadow: 0 8px 20px var(--shadow);
    }
    .status-row {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 10px;
      padding: 10px 12px;
      font-size: 13px;
    }
    .label { color: var(--muted); }
    .value { font-weight: 650; text-align: right; overflow-wrap: anywhere; }
    .ok { color: var(--accent); }
    .warn { color: #f5c542; }
    .bad { color: var(--danger); }
    .actions {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 8px;
      margin: 12px 0;
    }
    button, a.button {
      appearance: none;
      border: 1px solid var(--border);
      background: #22303a;
      color: var(--text);
      border-radius: 7px;
      min-height: 38px;
      padding: 8px 10px;
      font: inherit;
      font-size: 13px;
      text-decoration: none;
      cursor: pointer;
      text-align: center;
    }
    button:hover, a.button:hover { border-color: var(--accent); }
    button:disabled { opacity: .55; cursor: wait; }
    .panel {
      padding: 12px;
      margin-top: 12px;
    }
    .panel h2 {
      margin: 0 0 8px;
      font-size: 14px;
      letter-spacing: 0;
    }
    pre {
      margin: 0;
      padding: 10px;
      max-height: 280px;
      overflow: auto;
      border: 1px solid var(--border);
      border-radius: 7px;
      background: #0d1116;
      color: #d5dde5;
      font-size: 12px;
      white-space: pre-wrap;
      overflow-wrap: anywhere;
    }
    @media (max-width: 900px) {
      main { grid-template-columns: 1fr; }
      aside { border-right: 0; border-bottom: 1px solid var(--border); }
      section.terminal, iframe { min-height: 70vh; }
    }
  </style>
</head>
<body>
  <header>
    <h1>Codex Terminal</h1>
    <a class="button" href="/terminal/" target="_blank" rel="noreferrer">Terminal full screen</a>
  </header>
  <main>
    <aside>
      <div class="status-grid">
        <div class="status-row"><span class="label">Codex</span><span id="codex" class="value">...</span></div>
        <div class="status-row"><span class="label">Auth</span><span id="auth" class="value">...</span></div>
        <div class="status-row"><span class="label">tmux</span><span id="tmux" class="value">...</span></div>
        <div class="status-row"><span class="label">Context JSON</span><span id="context" class="value">...</span></div>
        <div class="status-row"><span class="label">Full permissions</span><span id="perms" class="value">...</span></div>
      </div>
      <div class="actions">
        <button data-action="doctor">Doctor</button>
        <button data-action="refresh-context">Refresh context</button>
        <button data-action="check-config">Check config</button>
        <button data-action="mcp-list">MCP list</button>
        <button data-action="list-plans">Edit plans</button>
        <a class="button" href="/terminal/" target="_blank" rel="noreferrer">Open terminal</a>
      </div>
      <div class="panel">
        <h2>Output</h2>
        <pre id="output">Ready.</pre>
      </div>
      <div class="panel">
        <h2>Startup</h2>
        <pre id="startup">Loading...</pre>
      </div>
    </aside>
    <section class="terminal">
      <iframe src="/terminal/" title="Codex terminal"></iframe>
    </section>
  </main>
  <script>
    const output = document.getElementById('output');
    const startup = document.getElementById('startup');
    const setText = (id, text, cls) => {
      const el = document.getElementById(id);
      el.textContent = text;
      el.className = 'value ' + (cls || '');
    };
    async function refreshStatus() {
      try {
        const res = await fetch('/api/status');
        const data = await res.json();
        setText('codex', data.codex_version || 'unavailable', data.codex_version === 'unavailable' ? 'bad' : 'ok');
        setText('auth', data.codex_auth_present ? 'present' : 'missing', data.codex_auth_present ? 'ok' : 'warn');
        setText('tmux', data.tmux_session_active ? 'active' : 'new session', data.tmux_session_active ? 'ok' : '');
        setText('context', data.context.json_context_exists ? 'present' : 'missing', data.context.json_context_exists ? 'ok' : 'warn');
        const full = data.options && data.options.codex_full_permissions;
        setText('perms', full ? 'ON' : 'OFF', full ? 'warn' : 'ok');
        startup.textContent = data.startup_log || 'No startup log yet.';
      } catch (error) {
        output.textContent = String(error);
      }
    }
    async function runAction(name, button) {
      button.disabled = true;
      output.textContent = 'Running ' + name + '...';
      try {
        const res = await fetch('/api/actions/' + name, { method: 'POST' });
        const data = await res.json();
        output.textContent = data.output || JSON.stringify(data, null, 2);
      } catch (error) {
        output.textContent = String(error);
      } finally {
        button.disabled = false;
        refreshStatus();
      }
    }
    document.querySelectorAll('button[data-action]').forEach(button => {
      button.addEventListener('click', () => runAction(button.dataset.action, button));
    });
    refreshStatus();
    setInterval(refreshStatus, 30000);
  </script>
</body>
</html>
"""


def create_app() -> web.Application:
    app = web.Application(client_max_size=16 * 1024 * 1024)
    app.router.add_get("/", index)
    app.router.add_get("/api/status", get_status)
    app.router.add_post("/api/actions/{name}", action)
    app.router.add_route("*", "/terminal", terminal_redirect)
    app.router.add_route("*", "/terminal/{tail:.*}", terminal_proxy)
    return app


if __name__ == "__main__":
    web.run_app(create_app(), host="0.0.0.0", port=7681)
