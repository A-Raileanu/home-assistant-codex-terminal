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
    }

    if name == "restart-terminal":
        exists = await run_command("tmux", "has-session", "-t", "codex", timeout=5)
        if not exists["ok"]:
            return web.json_response({
                "ok": True,
                "returncode": 0,
                "output": "Nu există o sesiune Codex activă de repornit. La următoarea deschidere se va afișa meniul de început.",
                "duration_ms": exists["duration_ms"],
            })
        result = await run_command("tmux", "kill-session", "-t", "codex", timeout=10)
        if result["ok"]:
            result["output"] = "Sesiunea Codex a fost oprită. Terminalul se reconectează și va afișa meniul de început."
        return web.json_response(result)

    if name not in commands:
        return web.json_response({"ok": False, "output": f"Acțiune necunoscută: {name}"}, status=404)

    args, timeout = commands[name]
    result = await run_command(*args, timeout=timeout)
    return web.json_response(result)


async def index(_: web.Request) -> web.Response:
    return web.Response(text=HTML, content_type="text/html")


async def terminal_redirect(_: web.Request) -> web.Response:
    raise web.HTTPFound("terminal/")


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
  <title>Terminal Codex</title>
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
    html, body {
      height: 100%;
      overflow: hidden;
    }
    body {
      margin: 0;
      background: var(--bg);
      color: var(--text);
      font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      line-height: 1.45;
      display: flex;
      flex-direction: column;
    }
    header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
      padding: 16px 18px;
      border-bottom: 1px solid var(--border);
      background: #0f1317;
      flex: 0 0 auto;
    }
    h1 { margin: 0; font-size: 18px; letter-spacing: 0; }
    main {
      display: grid;
      grid-template-columns: minmax(280px, 360px) minmax(0, 1fr);
      flex: 1 1 auto;
      min-height: 0;
    }
    aside {
      padding: 14px;
      border-right: 1px solid var(--border);
      background: var(--panel);
      overflow: auto;
      min-height: 0;
    }
    section.terminal {
      background: #101418;
      min-height: 0;
      overflow: hidden;
    }
    iframe {
      width: 100%;
      height: 100%;
      min-height: 0;
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
      display: flex;
      flex-direction: column;
      justify-content: center;
      gap: 2px;
    }
    button:hover, a.button:hover { border-color: var(--accent); }
    button:disabled { opacity: .55; cursor: wait; }
    .action-title { font-weight: 650; }
    .action-desc {
      color: var(--muted);
      font-size: 11px;
      line-height: 1.25;
    }
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
      body { overflow: auto; }
      main { grid-template-columns: 1fr; min-height: auto; }
      aside { border-right: 0; border-bottom: 1px solid var(--border); }
      section.terminal, iframe { min-height: 70vh; }
    }
  </style>
</head>
<body>
  <header>
    <h1>Terminal Codex</h1>
    <a class="button" href="#" data-terminal-link target="_blank" rel="noreferrer">
      <span class="action-title">Terminal pe tot ecranul</span>
    </a>
  </header>
  <main>
    <aside>
      <div class="status-grid">
        <div class="status-row"><span class="label">Versiune Codex</span><span id="codex" class="value">...</span></div>
        <div class="status-row"><span class="label">Autentificare</span><span id="auth" class="value">...</span></div>
        <div class="status-row"><span class="label">Sesiune terminal</span><span id="tmux" class="value">...</span></div>
        <div class="status-row"><span class="label">Context Home Assistant</span><span id="context" class="value">...</span></div>
        <div class="status-row"><span class="label">Permisiuni automate</span><span id="perms" class="value">...</span></div>
      </div>
      <div class="actions">
        <button data-action="doctor">
          <span class="action-title">Verifică sistemul</span>
          <span class="action-desc">Codex, API, unelte</span>
        </button>
        <button data-action="refresh-context">
          <span class="action-title">Actualizează contextul</span>
          <span class="action-desc">Citește datele HA</span>
        </button>
        <button data-action="check-config">
          <span class="action-title">Verifică configurația</span>
          <span class="action-desc">YAML și check_config</span>
        </button>
        <button data-action="mcp-list">
          <span class="action-title">Verifică integrarea MCP</span>
          <span class="action-desc">Uneltele HA pentru Codex</span>
        </button>
        <button data-action="restart-terminal">
          <span class="action-title">Repornește terminalul</span>
          <span class="action-desc">Revine la meniul de început</span>
        </button>
        <a class="button" href="#" data-terminal-link target="_blank" rel="noreferrer">
          <span class="action-title">Deschide terminalul separat</span>
          <span class="action-desc">Fereastră nouă</span>
        </a>
      </div>
      <div class="panel">
        <h2>Rezultat acțiune</h2>
        <pre id="output">Alege o acțiune din butoanele de mai sus.</pre>
      </div>
      <div class="panel">
        <h2>Pornire add-on</h2>
        <pre id="startup">Se încarcă...</pre>
      </div>
    </aside>
    <section class="terminal">
      <iframe id="terminal-frame" src="about:blank" title="Codex terminal"></iframe>
    </section>
  </main>
  <script>
    const output = document.getElementById('output');
    const startup = document.getElementById('startup');
    const path = window.location.pathname;
    const ingressBase = path.endsWith('/') ? path : path + '/';
    const ingressUrl = (suffix) => ingressBase + suffix.replace(/^\/+/, '');
    const terminalUrl = ingressUrl('terminal/');
    document.getElementById('terminal-frame').src = terminalUrl;
    document.querySelectorAll('[data-terminal-link]').forEach(link => {
      link.href = terminalUrl;
    });
    const setText = (id, text, cls) => {
      const el = document.getElementById(id);
      el.textContent = text;
      el.className = 'value ' + (cls || '');
    };
    async function refreshStatus() {
      try {
        const res = await fetch(ingressUrl('api/status'));
        const data = await res.json();
        setText('codex', data.codex_version || 'indisponibil', data.codex_version === 'unavailable' ? 'bad' : 'ok');
        setText('auth', data.codex_auth_present ? 'conectat' : 'lipsește', data.codex_auth_present ? 'ok' : 'warn');
        setText('tmux', data.tmux_session_active ? 'activă' : 'gata de pornire', data.tmux_session_active ? 'ok' : '');
        setText('context', data.context.json_context_exists ? 'generat' : 'lipsește', data.context.json_context_exists ? 'ok' : 'warn');
        const full = data.options && data.options.codex_full_permissions;
        setText('perms', full ? 'pornite' : 'oprite', full ? 'warn' : 'ok');
        startup.textContent = data.startup_log || 'Nu există jurnal de pornire încă.';
      } catch (error) {
        output.textContent = 'Nu am putut citi starea add-on-ului: ' + String(error);
      }
    }
    async function runAction(name, button) {
      const labels = {
        'doctor': 'Verific sistemul',
        'refresh-context': 'Actualizez contextul Home Assistant',
        'check-config': 'Verific configurația Home Assistant',
        'mcp-list': 'Verific integrarea MCP',
        'restart-terminal': 'Repornesc terminalul'
      };
      button.disabled = true;
      output.textContent = (labels[name] || 'Rulez acțiunea') + '...';
      try {
        const res = await fetch(ingressUrl('api/actions/' + name), { method: 'POST' });
        const data = await res.json();
        output.textContent = data.output || JSON.stringify(data, null, 2);
        if (name === 'restart-terminal') {
          setTimeout(() => {
            document.getElementById('terminal-frame').src = terminalUrl;
          }, 1000);
        }
      } catch (error) {
        output.textContent = 'Acțiunea nu a reușit: ' + String(error);
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
