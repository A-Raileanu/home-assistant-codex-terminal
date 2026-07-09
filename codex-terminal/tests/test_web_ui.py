import asyncio
import importlib.util
import pathlib
import unittest

from aiohttp import ClientSession, WSMsgType, web


ROOT = pathlib.Path(__file__).resolve().parents[2]
MODULE_PATH = ROOT / "codex-terminal" / "scripts" / "web-ui.py"
SPEC = importlib.util.spec_from_file_location("codex_terminal_web_ui", MODULE_PATH)
WEB_UI = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
SPEC.loader.exec_module(WEB_UI)


async def start_site(app: web.Application) -> tuple[web.AppRunner, str]:
    runner = web.AppRunner(app)
    await runner.setup()
    site = web.TCPSite(runner, "127.0.0.1", 0)
    await site.start()
    port = site._server.sockets[0].getsockname()[1]
    return runner, f"http://127.0.0.1:{port}"


class WebUiTests(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self) -> None:
        upstream = web.Application()
        self.upstream_websocket_closed = asyncio.Event()

        async def asset(request: web.Request) -> web.StreamResponse:
            response = web.StreamResponse(headers={"X-Upstream": "yes"})
            await response.prepare(request)
            await response.write(b"prima-")
            await asyncio.sleep(0)
            await response.write(b"a-doua")
            await response.write_eof()
            return response

        async def websocket(request: web.Request) -> web.WebSocketResponse:
            ws = web.WebSocketResponse()
            await ws.prepare(request)
            try:
                async for message in ws:
                    if message.type == WSMsgType.TEXT:
                        await ws.send_str(f"ecou:{message.data}")
                    elif message.type == WSMsgType.BINARY:
                        await ws.send_bytes(message.data)
            finally:
                self.upstream_websocket_closed.set()
            return ws

        async def websocket_closes(request: web.Request) -> web.WebSocketResponse:
            ws = web.WebSocketResponse()
            await ws.prepare(request)
            await ws.close(code=4001, message=b"upstream closed")
            return ws

        upstream.router.add_get("/asset", asset)
        upstream.router.add_get("/ws", websocket)
        upstream.router.add_get("/ws-close", websocket_closes)
        self.upstream_runner, upstream_url = await start_site(upstream)
        WEB_UI.TTYD_UPSTREAM = upstream_url
        self.proxy_runner, self.proxy_url = await start_site(WEB_UI.create_app())
        self.client = ClientSession()

    async def asyncTearDown(self) -> None:
        await self.client.close()
        await self.proxy_runner.cleanup()
        await self.upstream_runner.cleanup()

    async def test_relative_redirect_and_streamed_response(self) -> None:
        async with self.client.get(self.proxy_url + "/", allow_redirects=False) as response:
            self.assertEqual(response.status, 302)
            self.assertEqual(response.headers["Location"], "terminal/")

        async with self.client.get(self.proxy_url + "/terminal/asset") as response:
            self.assertEqual(response.status, 200)
            self.assertEqual(response.headers["X-Upstream"], "yes")
            self.assertEqual(await response.read(), b"prima-a-doua")

    async def test_websocket_is_bidirectional(self) -> None:
        websocket = await self.client.ws_connect(self.proxy_url + "/terminal/ws")
        await websocket.send_str("salut")
        response = await websocket.receive(timeout=2)
        self.assertEqual(response.data, "ecou:salut")
        await websocket.close()
        await asyncio.wait_for(self.upstream_websocket_closed.wait(), timeout=2)

    async def test_websocket_forwards_upstream_close_state(self) -> None:
        websocket = await self.client.ws_connect(self.proxy_url + "/terminal/ws-close")
        response = await websocket.receive(timeout=2)
        self.assertEqual(response.type, WSMsgType.CLOSE)
        self.assertEqual(response.data, 4001)

    async def test_unavailable_upstream_returns_clear_502(self) -> None:
        original = WEB_UI.TTYD_UPSTREAM
        WEB_UI.TTYD_UPSTREAM = "http://127.0.0.1:1"
        try:
            async with self.client.get(self.proxy_url + "/terminal/asset") as response:
                self.assertEqual(response.status, 502)
                self.assertIn("nu este disponibil", await response.text())
        finally:
            WEB_UI.TTYD_UPSTREAM = original


if __name__ == "__main__":
    unittest.main()
