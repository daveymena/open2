FROM node:20-bullseye
RUN npx playwright install-deps
WORKDIR /app
COPY . /app
RUN npm install -g opencode-ai
EXPOSE 3000
ENV PORT=3000
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 CMD curl -f http://127.0.0.1:3000/ || exit 1
CMD ["opencode", "web", "--hostname", "0.0.0.0", "--port", "3000"]