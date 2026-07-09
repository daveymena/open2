# ============================================================
# OpenCode Evolved — Imagen Docker completa
# Soporta: Node.js, Python, Go, Rust, Java, Ruby, PHP,
#          .NET, Deno, Bun, C/C++, Bash y más
# Para EasyPanel / Docker / Servidor local
# ============================================================

FROM ubuntu:24.04

# Evitar prompts interactivos durante la instalación
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# ---- Herramientas base ---- #
RUN apt-get update && apt-get install -y \
    # Herramientas esenciales
    curl wget git unzip zip tar gzip \
    build-essential gcc g++ make cmake \
    # Para SSL/TLS
    ca-certificates gnupg \
    # Útiles
    jq tree htop nano vim less \
    # Para lenguajes
    libssl-dev libffi-dev zlib1g-dev \
    pkg-config libbz2-dev libreadline-dev \
    libsqlite3-dev libncurses5-dev \
    # Para Java
    fontconfig \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# NODE.JS 22 (LTS)
# ============================================================
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm@latest \
    && npm install -g pnpm yarn \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# BUN (Runtime JS/TS ultrarrápido - requerido por OpenCode)
# ============================================================
RUN curl -fsSL https://bun.sh/install | bash \
    && cp /root/.bun/bin/bun /usr/local/bin/bun \
    && ln -sf /usr/local/bin/bun /usr/local/bin/bunx

# ============================================================
# PYTHON 3.12 + pip + uv + poetry
# ============================================================
RUN apt-get update && apt-get install -y \
    python3.12 python3.12-dev python3.12-venv python3-pip \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.12 1 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1 \
    && pip3 install --no-cache-dir uv poetry \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# GO 1.23
# ============================================================
RUN curl -fsSL https://go.dev/dl/go1.23.4.linux-amd64.tar.gz -o /tmp/go.tar.gz \
    && tar -C /usr/local -xzf /tmp/go.tar.gz \
    && rm /tmp/go.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"
ENV GOPATH="/root/go"
ENV PATH="${GOPATH}/bin:${PATH}"

# ============================================================
# RUST + CARGO (via rustup)
# ============================================================
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --no-modify-path --profile minimal
ENV PATH="/root/.cargo/bin:${PATH}"

# ============================================================
# JAVA 21 (JDK) + Maven + Gradle
# ============================================================
RUN apt-get update && apt-get install -y \
    openjdk-21-jdk maven \
    && rm -rf /var/lib/apt/lists/*
ENV JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Gradle
RUN curl -fsSL https://services.gradle.org/distributions/gradle-8.11.1-bin.zip -o /tmp/gradle.zip \
    && unzip -d /opt /tmp/gradle.zip \
    && mv /opt/gradle-8.11.1 /opt/gradle \
    && rm /tmp/gradle.zip
ENV PATH="/opt/gradle/bin:${PATH}"

# ============================================================
# RUBY 3.3
# ============================================================
RUN apt-get update && apt-get install -y \
    ruby ruby-dev ruby-bundler \
    && gem install rails --no-document \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# PHP 8.3 + Composer
# ============================================================
RUN apt-get update && apt-get install -y \
    php8.3 php8.3-cli php8.3-common \
    php8.3-curl php8.3-mbstring php8.3-xml \
    php8.3-zip php8.3-pgsql php8.3-mysql \
    && rm -rf /var/lib/apt/lists/*
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# ============================================================
# .NET 8 SDK
# ============================================================
RUN curl -fsSL https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -o /tmp/packages-microsoft-prod.deb \
    && dpkg -i /tmp/packages-microsoft-prod.deb \
    && rm /tmp/packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y dotnet-sdk-8.0 \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# DENO
# ============================================================
RUN curl -fsSL https://deno.land/install.sh | sh \
    && cp /root/.deno/bin/deno /usr/local/bin/deno

# ============================================================
# OPENCODE (binario oficial de SST)
# ============================================================
ARG OPENCODE_VERSION=1.2.27
RUN curl -fsSL "https://github.com/sst/opencode/releases/download/v${OPENCODE_VERSION}/opencode-linux-x64.tar.gz" \
    -o /tmp/opencode.tar.gz \
    && tar -xzf /tmp/opencode.tar.gz -C /tmp \
    && mv /tmp/opencode /usr/local/bin/opencode \
    && chmod +x /usr/local/bin/opencode \
    && rm /tmp/opencode.tar.gz

# ============================================================
# WEB OPERATOR — Automatización de navegador con Playwright
# ============================================================
RUN apt-get update && apt-get install -y \
    libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 \
    libgbm1 libasound2 libxkbcommon0 libxcomposite1 libxdamage1 \
    libxfixes3 libxrandr2 libpango-1.0-0 libcairo2 libx11-6 libx11-xcb1 \
    libxcb1 libxext6 libxss1 libxtst6 libxcb-dri3-0 fonts-liberation \
    xvfb x11vnc novnc websockify procps netcat-openbsd \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# CONFIGURACIÓN DEL WORKSPACE
# ============================================================
WORKDIR /workspace

# Copiar código del proyecto al workspace
COPY . /workspace/artifacts/

# ── Limpiar archivos basura que puedan haber llegado ──────
RUN rm -f /workspace/artifacts/=* 2>/dev/null || true

# ── Instalar deps del web-operator ───────────────────────
RUN cd /workspace/artifacts/web-operator && npm install --ignore-scripts 2>/dev/null || true
RUN cd /workspace/artifacts/web-operator && npm install playwright --no-save 2>/dev/null || true

# ── Instalar deps del proxy + frontend ───────────────────
RUN cd /workspace/artifacts/artifacts/opencode-ui && npm install --ignore-scripts 2>/dev/null || true \
    || (cd /workspace/artifacts/opencode-ui && npm install --ignore-scripts 2>/dev/null || true)

# ── Compilar frontend React (opcional, fallback al standalone) ──
RUN cd /workspace/artifacts/artifacts/opencode-ui 2>/dev/null && npx --yes vite build 2>&1 | tail -3 \
    || cd /workspace/artifacts/opencode-ui 2>/dev/null && npx --yes vite build 2>&1 | tail -3 \
    || echo "Build opcional omitido - usando standalone"

# ── Copiar frontend compilado si existe ──────────────────
RUN if [ -f "/workspace/artifacts/artifacts/opencode-ui/dist/public/index.html" ]; then \
    mkdir -p /app/ui && cp -r /workspace/artifacts/artifacts/opencode-ui/dist/public/* /app/ui/ && \
    echo "Frontend React compilado (artifacts/artifacts)"; \
    elif [ -f "/workspace/artifacts/opencode-ui/dist/public/index.html" ]; then \
    mkdir -p /app/ui && cp -r /workspace/artifacts/opencode-ui/dist/public/* /app/ui/ && \
    echo "Frontend React compilado (artifacts)"; \
    else \
    echo "Usando frontend standalone"; fi

# ── Frontend standalone (siempre disponible como fallback) ─
RUN mkdir -p /app/ui && \
    (cp /workspace/artifacts/artifacts/opencode-ui/ui/index.html /app/ui/index.html 2>/dev/null || \
     cp /workspace/artifacts/opencode-ui/ui/index.html /app/ui/index.html 2>/dev/null || \
     echo "Standalone UI no encontrado")

# ── Instalar Playwright Chromium ─────────────────────────
RUN cd /workspace/artifacts/web-operator && npx playwright install chromium --with-deps 2>/dev/null || true

# ── Simlinks para que el start.sh encuentre los paths correctos ──
RUN ln -sf /workspace/artifacts/artifacts/opencode-ui /workspace/artifacts/opencode-ui-compiled 2>/dev/null || true

# ============================================================
# CONFIGURACIÓN DE OPENCODE
# ============================================================
COPY .config/opencode/ /root/.config/opencode/
COPY .opencode/ /workspace/.opencode/
COPY .env.example /workspace/.env.example
COPY proyectos/README.md /workspace/proyectos/README.md 2>/dev/null || true

# Crear package.json en workspace para MCP servers
RUN echo '{"name":"workspace","version":"1.0.0","private":true}' > /workspace/package.json

# Crear estructura de directorios
RUN mkdir -p \
    /workspace/proyectos \
    /workspace/artifacts/bin \
    /root/.local/share/opencode \
    /root/.cache/opencode \
    /root/.config/opencode

# Copiar scripts MCP al directorio artifacts/bin
RUN (cp /workspace/artifacts/bin/mcp-computer.mjs /workspace/artifacts/artifacts/bin/ 2>/dev/null || true) && \
    (cp /workspace/artifacts/bin/mcp-body.mjs /workspace/artifacts/artifacts/bin/ 2>/dev/null || true)

# ============================================================
# SCRIPT DE INICIO
# ============================================================
COPY docker/start.sh /usr/local/bin/start-opencode.sh
RUN chmod +x /usr/local/bin/start-opencode.sh

# Puertos: Proxy(3000) + WebOperator(3001) + VNC(6080)
EXPOSE 3000 3001 6080

# Variables de entorno por defecto
ENV PORT=3000
ENV OPENCODE_WORKSPACE=/workspace
ENV OPERATOR_PORT=3001
ENV API_SERVER_PORT=3001
ENV DISPLAY=:99
ENV TZ=America/Bogota

# Volúmenes para persistencia
VOLUME ["/workspace", "/root/.local/share/opencode"]

CMD ["/usr/local/bin/start-opencode.sh"]
