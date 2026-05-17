ARG BUILD_FROM
FROM ${BUILD_FROM}

ARG CODEX_VERSION=0.130.0

RUN apk add --no-cache \
    bash \
    curl \
    git \
    jq \
    nano \
    nodejs \
    npm \
    py3-aiohttp \
    py3-pip \
    py3-requests \
    py3-yaml \
    python3 \
    ripgrep \
    tmux \
    tree \
    ttyd \
    uv \
    vim \
    wget \
    yq \
    && npm install -g "@openai/codex@${CODEX_VERSION}" \
    && npm cache clean --force

WORKDIR /config

COPY run.sh /run.sh
COPY scripts/ /opt/scripts/

RUN chmod +x /run.sh \
    && chmod +x /opt/scripts/*.sh

CMD ["/run.sh"]
