#!/usr/bin/env python3

import asyncio
import os

from aiohttp import ClientSession, WSMsgType, web


TTYD_UPSTREAM = os.environ.get("TTYD_UPSTREAM", "http://127.0.0.1:7682")


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
        if key.lower() not in {"host", "content-length"}
    }

    async with ClientSession() as session:
        async with session.request(
            request.method,
            upstream_url,
            data=body,
            headers=headers,
            allow_redirects=False,
        ) as upstream:
            excluded = {"content-encoding", "transfer-encoding", "connection", "content-length"}
            response_headers = {
                key: value
                for key, value in upstream.headers.items()
                if key.lower() not in excluded
            }
            payload = await upstream.read()
            return web.Response(status=upstream.status, headers=response_headers, body=payload)


async def websocket_proxy(request: web.Request, upstream_url: str) -> web.WebSocketResponse:
    downstream = web.WebSocketResponse()
    await downstream.prepare(request)

    headers = {
        key: value
        for key, value in request.headers.items()
        if key.lower() not in {"host", "connection", "upgrade"}
    }

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

            tasks = [
                asyncio.create_task(client_to_upstream()),
                asyncio.create_task(upstream_to_client()),
            ]
            done, pending = await asyncio.wait(tasks, return_when=asyncio.FIRST_COMPLETED)
            for task in pending:
                task.cancel()
            for task in done:
                task.result()

    return downstream


def create_app() -> web.Application:
    app = web.Application(client_max_size=16 * 1024 * 1024)
    app.router.add_route("*", "/", terminal_redirect)
    app.router.add_route("*", "/terminal", terminal_redirect)
    app.router.add_route("*", "/terminal/{tail:.*}", terminal_proxy)
    return app


if __name__ == "__main__":
    web.run_app(create_app(), host="0.0.0.0", port=7681)
