#!/usr/bin/env python3

import asyncio
import os
from contextlib import suppress

from aiohttp import ClientError, ClientSession, WSMsgType, web


TTYD_UPSTREAM = os.environ.get("TTYD_UPSTREAM", "http://127.0.0.1:7682")
HTTP_CLIENT_KEY = web.AppKey("http_client", ClientSession)
HOP_BY_HOP_HEADERS = {
    "connection",
    "keep-alive",
    "proxy-authenticate",
    "proxy-authorization",
    "te",
    "trailer",
    "transfer-encoding",
    "upgrade",
}


async def http_client_context(app: web.Application):
    app[HTTP_CLIENT_KEY] = ClientSession(auto_decompress=False)
    yield
    await app[HTTP_CLIENT_KEY].close()


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
    headers = {
        key: value
        for key, value in request.headers.items()
        if key.lower() not in HOP_BY_HOP_HEADERS | {"host", "content-length"}
    }

    session: ClientSession = request.app[HTTP_CLIENT_KEY]
    try:
        async with session.request(
            request.method,
            upstream_url,
            data=body,
            headers=headers,
            allow_redirects=False,
        ) as upstream:
            response_headers = {
                key: value
                for key, value in upstream.headers.items()
                if key.lower() not in HOP_BY_HOP_HEADERS
            }
            response = web.StreamResponse(status=upstream.status, headers=response_headers)
            await response.prepare(request)
            if request.method != "HEAD":
                async for chunk in upstream.content.iter_chunked(64 * 1024):
                    await response.write(chunk)
            await response.write_eof()
            return response
    except ClientError as exc:
        raise web.HTTPBadGateway(text="Terminalul nu este disponibil momentan.") from exc


async def websocket_proxy(request: web.Request, upstream_url: str) -> web.WebSocketResponse:
    headers = {
        key: value
        for key, value in request.headers.items()
        if key.lower() not in HOP_BY_HOP_HEADERS | {"host"}
    }
    session: ClientSession = request.app[HTTP_CLIENT_KEY]
    try:
        upstream = await session.ws_connect(upstream_url, headers=headers, heartbeat=30)
    except ClientError as exc:
        raise web.HTTPBadGateway(text="Conexiunea terminalului nu este disponibilă.") from exc

    downstream = web.WebSocketResponse(heartbeat=30)
    await downstream.prepare(request)

    async def client_to_upstream() -> None:
        async for msg in downstream:
            if msg.type == WSMsgType.TEXT:
                await upstream.send_str(msg.data)
            elif msg.type == WSMsgType.BINARY:
                await upstream.send_bytes(msg.data)
            elif msg.type == WSMsgType.ERROR:
                raise downstream.exception() or ConnectionError("Conexiunea clientului a eșuat")
        await upstream.close(code=downstream.close_code or 1000)

    async def upstream_to_client() -> None:
        async for msg in upstream:
            if msg.type == WSMsgType.TEXT:
                await downstream.send_str(msg.data)
            elif msg.type == WSMsgType.BINARY:
                await downstream.send_bytes(msg.data)
            elif msg.type == WSMsgType.ERROR:
                raise upstream.exception() or ConnectionError("Conexiunea terminalului a eșuat")
        await downstream.close(code=upstream.close_code or 1000)

    tasks = {
        asyncio.create_task(client_to_upstream()),
        asyncio.create_task(upstream_to_client()),
    }
    done, pending = await asyncio.wait(tasks, return_when=asyncio.FIRST_COMPLETED)
    errors = [result for result in await asyncio.gather(*done, return_exceptions=True) if result]
    for task in pending:
        task.cancel()
    await asyncio.gather(*pending, return_exceptions=True)

    if errors and not downstream.closed:
        await downstream.close(code=1011, message=b"Terminal relay failed")
    if not upstream.closed:
        with suppress(Exception):
            await upstream.close()

    return downstream


def create_app() -> web.Application:
    app = web.Application(client_max_size=16 * 1024 * 1024)
    app.cleanup_ctx.append(http_client_context)
    app.router.add_route("*", "/", terminal_redirect)
    app.router.add_route("*", "/terminal", terminal_redirect)
    app.router.add_route("*", "/terminal/{tail:.*}", terminal_proxy)
    return app


if __name__ == "__main__":
    web.run_app(create_app(), host="0.0.0.0", port=7681)
