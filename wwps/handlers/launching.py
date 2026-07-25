from __future__ import annotations

import json
import re

from aiohttp import web

from .. import config, game_data, logging_setup, metrics

log = logging_setup.get(__name__)

PLACEHOLDER_HOST = "http://youtube.com"

_template: str | None = None


def _load_template() -> str | None:
    global _template
    if _template is None:
        raw = game_data.gamedata_cache.get("hspLaunchingInfos")
        if raw is None:
            return None
        _template = raw
    return _template


def _public_base(request: web.Request) -> str:
    if config.public_url:
        return config.public_url.rstrip("/")
    proto = request.headers.get("X-Forwarded-Proto")
    host = request.headers.get("X-Forwarded-Host") or request.headers.get("Host")
    if host:
        scheme = proto or request.scheme
        return f"{scheme}://{host}".rstrip("/")
    return str(request.url.origin()).rstrip("/")


def _force_https(body: str) -> str:
    return re.sub(r'"http://([^"]+)"', r'"https://\1"', body)


def _ensure_device_idps(body: str, base: str) -> str:
    try:
        payload = json.loads(body)
    except json.JSONDecodeError:
        return body
    idp = payload.get("idpInfo")
    if not isinstance(idp, dict):
        return body
    for name in ("toast", "guest"):
        if name not in idp:
            idp[name] = {
                "selected": "Y",
                "loginable": "Y",
                "consumerKey": "DUMMY_KEY",
                "consumerSecret": "DUMMY_SECRET",
                "redirectionUrl": base,
            }
    return json.dumps(payload)


async def launching(request: web.Request) -> web.Response:
    template = _load_template()
    if template is None:
        log.error("hspLaunchingInfos not found in game data")
        return web.json_response({"state": 1, "stateMessage": "config missing",
                                  "loginable": "N", "playable": "N"}, status=200)
    base = _public_base(request)
    body = template.replace(PLACEHOLDER_HOST, base)
    if base.startswith("https://"):
        body = _force_https(body)
    body = _ensure_device_idps(body, base)
    metrics.incr("launching_served")
    log.info("served launching info to %s (base %s)",
             request.remote or "?", base)
    return web.Response(text=body, content_type="application/json")
