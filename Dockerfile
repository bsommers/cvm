FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_VERSION=20

# System update and base tools
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    jq \
    unzip \
    zip \
    tar \
    build-essential \
    make \
    cmake \
    ca-certificates \
    python3 \
    python3-pip \
    python3-venv \
    vim \
    ripgrep \
    fd-find \
    procps \
    lsof \
    dnsutils \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20 LTS
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code globally
RUN npm install -g @anthropic-ai/claude-code

# Use the built-in 'ubuntu' user (UID 1000) — claude blocks --dangerously-skip-permissions as root
RUN mkdir -p /workspace && chown ubuntu:ubuntu /workspace

USER ubuntu
WORKDIR /workspace
