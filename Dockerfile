FROM node:22-bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g opencode-ai@1.18.3

EXPOSE 4096

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -sf http://127.0.0.1:4096/global/health || exit 1

CMD ["opencode", "serve", "--hostname", "0.0.0.0", "--port", "4096"]