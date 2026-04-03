FROM node:20-slim AS base

# Install Python + pip for nanobot
RUN apt-get update && apt-get install -y python3 python3-pip python3-venv curl && \
    rm -rf /var/lib/apt/lists/*

# Install OWS CLI
RUN curl -fsSL https://docs.openwallet.sh/install.sh | bash
ENV PATH="/root/.ows/bin:$PATH"

# Install perp-cli + defi-cli
RUN npm install -g perp-cli @hypurrquant/defi-cli

# Install nanobot
RUN python3 -m venv /opt/nanobot && \
    /opt/nanobot/bin/pip install nanobot-ai
ENV PATH="/opt/nanobot/bin:$PATH"

# Setup workspace
WORKDIR /atlas
COPY config.json .
COPY system-prompt.md .
COPY start.sh .
COPY demo.sh .
COPY setup-workspace.sh .
COPY policies/ policies/
COPY workspace/ workspace/

RUN chmod +x start.sh demo.sh setup-workspace.sh

# OWS vault mount point
VOLUME /root/.ows

# Default command
ENTRYPOINT ["./start.sh"]
