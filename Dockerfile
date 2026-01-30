# Clawbot/Moltbot Gateway Dockerfile
FROM node:22-bookworm

# Metadata
LABEL maintainer="eliflowi"
LABEL description="Clawbot AI Agent Gateway"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Install Bun (required for build scripts)
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

# Enable corepack for pnpm
RUN corepack enable

# Configure npm for global installs
RUN npm config set prefix /usr/local && \
    npm install -g clawdbot@latest

# Use existing node user (UID 1000)
RUN usermod -d /home/clawbot -m node && \
    groupmod -n clawbot node && \
    usermod -l clawbot node

# Create necessary directories with correct permissions
RUN mkdir -p /home/clawbot/.clawdbot /home/clawbot/clawd /home/clawbot/logs && \
    chown -R clawbot:clawbot /home/clawbot

# Set working directory
WORKDIR /home/clawbot

# Switch to non-root user
USER clawbot

# Set environment
ENV NODE_ENV=production
ENV HOME=/home/clawbot
ENV PATH="/usr/local/bin:${PATH}"

# Expose gateway port (internal only)
EXPOSE 18789

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -sf http://localhost:18789/health || exit 1

# Default command - start gateway
CMD ["clawdbot", "gateway", "--bind", "lan"]
