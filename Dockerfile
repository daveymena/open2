FROM node:20-bullseye

# FORCE REBUILD - 2026-07-11-17:15 - Fix startup sequence
# Instalar dependencias del sistema requeridas para Playwright
RUN npx playwright install-deps

# Establecer directorio de trabajo
WORKDIR /app

# Copiar el código fuente al contenedor
COPY . /app

# Instalar OpenCode y MiMo globalmente
RUN npm install -g opencode-ai @mimo-ai/cli pm2

# Instalar dependencias del proxy (opencode-ui)
RUN cd artifacts/opencode-ui && npm install

# NOTA: No construimos el frontend React porque OpenCode usa interfaz nativa.
# El proxy solo sirve archivos estáticos de /public (shell.css, shell.js)

# Instalar dependencias del web operator
RUN cd web-operator && npm install

# Instalar los navegadores de Playwright para el Web Operator
RUN cd web-operator && npx playwright install chromium

# Exponer los puertos principales (3000: OpenCode, 3001: Web Operator)
EXPOSE 3000
EXPOSE 3001
EXPOSE 4000

# Healthcheck para verificar que el proxy está respondiendo
# Usamos curl con --fail para que solo retorne 0 si el código HTTP es 2xx o 3xx
# Aceptamos códigos 200-499 (incluyendo 401) como "saludable"
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:3000/__health || curl -f http://localhost:3000/ || exit 1

# Script de arranque
CMD ["bash", "docker/start.sh"]
