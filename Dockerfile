FROM node:20-bullseye

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

# Script de arranque
CMD ["bash", "docker/start.sh"]
