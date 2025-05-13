FROM debian:bookworm as node

# Install dependencies for Puppeteer
RUN apt-get update && apt-get install -y --no-install-recommends \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libasound2 \
    libpangocairo-1.0-0 \
    libpango-1.0-0 \
    libgbm1 \
    libnss3 \
    libxshmfence1 \
    ca-certificates \
    fonts-liberation \
    libappindicator3-1 \
    libgtk-3-0 \
    wget \
    xdg-utils \
    lsb-release \
    fonts-noto-color-emoji && rm -rf /var/lib/apt/lists/*

# Install Chromium browser
RUN apt-get update && apt-get install -y chromium && \
    rm -rf /var/lib/apt/lists/*

RUN rm /bin/sh && ln -s /bin/bash /bin/sh
RUN apt-get update \
    && apt-get install -y \
    curl build-essential \
    autoconf automake cmake \
    git gcc g++ clang \
    libglib2.0-dev libssl-dev \
    zlib1g-dev python3-dev \
    python3-venv python3-pip \
    && apt-get -y autoclean

# nvm environment variables
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 20.9.0

# install nvm
# https://github.com/creationix/nvm#install-script
RUN curl --silent -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.2/install.sh | bash

# install node and npm
RUN source $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

# add node and npm to path so the commands are available
ENV NODE_PATH $NVM_DIR/versions/node/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

FROM node
# Install n8n
RUN npm install -g n8n

RUN mkdir -p $HOME/.n8n/nodes && cd $HOME/.n8n/nodes && npm install \
    n8n-nodes-mcp \
    n8n-nodes-document-generator \
    n8n-nodes-globals \
    n8n-nodes-edit-image-plus \
    n8n-nodes-text-manipulation \
    n8n-nodes-pgp \
    n8n-nodes-puppeteer \
    n8n-nodes-data-validation

# Add npm global bin to PATH to ensure n8n executable is found
ENV PATH="$NODE_PATH/n8n/bin:$PATH"

# Set environment variables
ENV N8N_LOG_LEVEL=info

# Expose the n8n port
EXPOSE 5678

# Create proper entrypoint scripts with shebang
RUN printf '#!/bin/sh\nexec n8n worker\n' > /worker && \
    printf '#!/bin/sh\nexec n8n webhook\n' > /webhook && \
    chmod +x /worker /webhook

# Start n8n (default command)
CMD ["n8n", "start"]
