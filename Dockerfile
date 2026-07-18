FROM node:20-bullseye

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg \
    libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 \
    libgbm1 libasound2 libxkbcommon0 libxcomposite1 libxdamage1 \
    libxfixes3 libxrandr2 libpango-1.0-0 libcairo2 \
    fonts-liberation \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g opencode-ai@1.18.3

RUN npx playwright install chromium --with-deps 2>/dev/null || true

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -sf http://127.0.0.1:3000/ || exit 1

CMD ["opencode", "web", "--hostname", "0.0.0.0", "--port", "3000"]