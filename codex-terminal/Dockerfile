ARG BUILD_FROM
FROM ${BUILD_FROM}

ARG CODEX_VERSION=0.144.1
ARG HA_MCP_VERSION=7.12.0

ENV BUNDLED_HA_MCP_VERSION=${HA_MCP_VERSION}

RUN apk add --no-cache \
    bash \
    bubblewrap \
    curl \
    git \
    jq \
    libgcc \
    nano \
    nodejs \
    npm \
    ripgrep \
    tmux \
    tree \
    ttyd \
    uv \
    vim \
    websocat \
    wget \
    yq \
    && npm install -g "@openai/codex@${CODEX_VERSION}" \
    && npm cache clean --force \
    && apk add --no-cache --virtual .ha-mcp-build-deps \
        build-base \
        cargo \
        libffi-dev \
        openssl-dev \
    && python3 -m pip install --no-cache-dir \
        "aiohttp==3.14.1" \
        "requests==2.34.2" \
        "PyYAML==6.0.3" \
    && UV_PYTHON_PREFERENCE=only-system uv venv --python /usr/local/bin/python3 /opt/ha-mcp \
    && UV_PYTHON_PREFERENCE=only-system uv pip install \
        --python /opt/ha-mcp/bin/python \
        "ha-mcp==${HA_MCP_VERSION}" \
    && test "$(/opt/ha-mcp/bin/python -c \
        'import ha_mcp, importlib.metadata; print(importlib.metadata.version("ha-mcp"))')" = "${HA_MCP_VERSION}" \
    && apk del .ha-mcp-build-deps

WORKDIR /config

COPY run.sh /run.sh
COPY scripts/ /opt/scripts/
COPY skills/ /opt/skills/

RUN chmod +x /run.sh \
    && chmod +x /opt/scripts/*.sh

CMD ["/run.sh"]
