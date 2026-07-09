#!/bin/bash
# ============================================================
# OpenCode Evolved — Script de inicio Docker/EasyPanel
# Soporta: FreeModel, OpenAI, Anthropic, Groq, Puter, GitHub
#          + PostgreSQL Easypanel + Proxy Dark Glassmorphism
# ============================================================
# NO usar set -e: algunos servicios opcionales pueden fallar

echo "╔══════════════════════════════════════════╗"
echo "║        OpenCode  E V O L V E D           ║"
echo "╚══════════════════════════════════════════╝"
echo "  Version: $(opencode --version 2>/dev/null || echo '1.2.27')"

# ---- Cargar .env si existe ---- #
if [ -f "/workspace/.env" ]; then
  echo "  📄 Cargando .env..."
  set -o allexport
  source /workspace/.env
  set +o allexport
fi

# ──────────────────────────────────────────────────────────
#  PROVEEDORES DE IA
# ──────────────────────────────────────────────────────────
echo ""
echo "  🤖 Proveedores de IA detectados:"

if [ -n "$FREEMODEL_API_KEY" ]; then
  echo "     ✅ FreeModel GPT-4o (gratis)"
  export FREEMODEL_BASE_URL="${FREEMODEL_BASE_URL:-https://api.freemodel.dev/v1}"
  export FREEMODEL_MODEL="${FREEMODEL_MODEL:-gpt-4o}"
fi

if [ -n "$ANTHROPIC_API_KEY" ]; then
  echo "     ✅ Anthropic Claude"
fi

if [ -n "$OPENAI_API_KEY" ]; then
  echo "     ✅ OpenAI GPT-4o"
fi

if [ -n "$GOOGLE_GENERATIVE_AI_API_KEY" ]; then
  echo "     ✅ Google Gemini"
fi

if [ -n "$GROQ_API_KEY" ]; then
  echo "     ✅ Groq (Llama, Mixtral - gratis)"
fi

if [ -n "$OPENROUTER_API_KEY" ]; then
  echo "     ✅ OpenRouter (60+ modelos)"
fi

if [ -n "$CEREBRAS_API_KEY" ]; then
  echo "     ✅ Cerebras (ultrarrápido - gratis)"
fi

if [ -n "$MISTRAL_API_KEY" ]; then
  echo "     ✅ Mistral AI"
fi

if [ -n "$XAI_API_KEY" ]; then
  echo "     ✅ xAI Grok"
fi

if [ -n "$PUTER_AUTH_TOKEN" ]; then
  echo "     ✅ Puter.js (texto gratis)"
fi

if [ -n "$GITHUB_TOKEN" ]; then
  echo "     ✅ GitHub Token"
fi

# ── Ollama local ────────────────────────────────────────────
if [ -n "$OLLAMA_HOST" ]; then
  export OLLAMA_BASE_URL="$OLLAMA_HOST"
  echo "     ✅ Ollama en $OLLAMA_HOST"
elif curl -s --connect-timeout 2 http://ollama:11434 >/dev/null 2>&1; then
  export OLLAMA_BASE_URL="http://ollama:11434"
  echo "     ✅ Ollama detectado automáticamente"
fi

# ──────────────────────────────────────────────────────────
#  BASE DE DATOS (Easypanel PostgreSQL)
# ──────────────────────────────────────────────────────────
echo ""
if [ -n "$EASYPANEL_DATABASE_URL" ]; then
  echo "  🗄️  BD Easypanel: ${DB_HOST:-?}:${DB_PORT:-5432}/${DB_NAME:-?}"
  # Ejecutar migraciones si psql está disponible
  if command -v psql >/dev/null 2>&1 && [ -f "/workspace/artifacts/opencode-ui/db/schema.sql" ]; then
    echo "  📦 Aplicando schema de BD..."
    psql "$EASYPANEL_DATABASE_URL" -f /workspace/artifacts/opencode-ui/db/schema.sql 2>/dev/null \
      && echo "  ✅ Schema aplicado" \
      || echo "  ⚠️  Schema ya existía o error menor (normal)"
  fi
elif [ -n "$DATABASE_URL" ]; then
  export EASYPANEL_DATABASE_URL="$DATABASE_URL"
  echo "  🗄️  BD: $DATABASE_URL"
fi

# ──────────────────────────────────────────────────────────
#  VARIABLES DE ENTORNO
# ──────────────────────────────────────────────────────────
export DISPLAY="${DISPLAY:-:99}"
export TZ="${TZ:-America/Bogota}"

# ──────────────────────────────────────────────────────────
#  PANTALLA VIRTUAL (Xvfb + VNC) — opcional, no mata el inicio si falla
# ──────────────────────────────────────────────────────────
echo ""
echo "  🖥️  Iniciando pantalla virtual..."
Xvfb :99 -screen 0 1920x1080x24 -nolisten tcp 2>/dev/null &
sleep 2

# x11vnc y noVNC son opcionales
x11vnc -display :99 -nopw -listen localhost -xkb -forever -quiet 2>/dev/null &
sleep 1
websockify --web=/usr/share/novnc/ 0.0.0.0:6080 localhost:5900 >/dev/null 2>&1 &
echo "  ✅ VNC listo en :6080 (si está disponible)"

# ──────────────────────────────────────────────────────────
#  INSTALAR MCP SERVERS (si no existen)
# ──────────────────────────────────────────────────────────
if [ ! -d "/workspace/node_modules/@modelcontextprotocol" ]; then
  echo ""
  echo "  📦 Instalando MCP servers..."
  cd /workspace
  npm install --save \
    @modelcontextprotocol/server-filesystem \
    @modelcontextprotocol/server-memory \
    @modelcontextprotocol/server-sequential-thinking \
    @playwright/mcp \
    2>/dev/null || echo "  ⚠️  Algunos MCP servers no se instalaron (no crítico)"
fi

# ──────────────────────────────────────────────────────────
#  COPIAR SCRIPTS BIN AL WORKSPACE (para MCP)
# ──────────────────────────────────────────────────────────
mkdir -p /workspace/artifacts/bin
if [ -f "/workspace/artifacts/bin/mcp-computer.mjs" ]; then
  echo "  ✅ Scripts MCP ya copiados"
else
  cp /workspace/artifacts/mcp-computer.mjs /workspace/artifacts/bin/ 2>/dev/null || true
  cp /workspace/artifacts/mcp-body.mjs /workspace/artifacts/bin/ 2>/dev/null || true
fi

# ──────────────────────────────────────────────────────────
#  ARRANQUE DE MOTORES (OPENCODE & MIMO)
# ──────────────────────────────────────────────────────────
PROXY_PORT="${PORT:-3000}"
MIMO_PROXY_PORT="4000"

OC_PORT="$(( PROXY_PORT + 1 ))"
MIMO_PORT="$(( MIMO_PROXY_PORT + 1 ))"

WORKSPACE="${OPENCODE_WORKSPACE:-/workspace}"

mkdir -p "$WORKSPACE/proyectos"

echo ""
echo "  🚀 Iniciando motor OpenCode en puerto $OC_PORT..."
PORT=$OC_PORT opencode serve \
  --port "$OC_PORT" \
  --no-auth \
  --hostname 0.0.0.0 &
OC_PID=$!

echo "  🚀 Iniciando motor MiMo Code en puerto $MIMO_PORT..."
PORT=$MIMO_PORT mimo serve \
  --port "$MIMO_PORT" \
  --no-auth \
  --hostname 0.0.0.0 &
MIMO_PID=$!

echo "  ⏳ Esperando a que OpenCode inicie (hasta 60s)..."
for i in $(seq 1 60); do
  if curl -s --connect-timeout 1 "http://localhost:$OC_PORT/" >/dev/null 2>&1; then
    echo "  ✅ OpenCode listo (${i}s)"
    break
  fi
  sleep 1
done

# ── Web Operator (automatización de navegador) ───────────
OPERATOR_PORT="${OPERATOR_PORT:-3001}"
if [ -f "/workspace/artifacts/web-operator/api-server.js" ]; then
  echo "  🤖 Iniciando Web Operator en puerto $OPERATOR_PORT..."
  cd /workspace/artifacts/web-operator
  OPERATOR_PORT=$OPERATOR_PORT PORT=$OPERATOR_PORT \
    FREEMODEL_API_KEY="${FREEMODEL_API_KEY}" \
    FREEMODEL_BASE_URL="${FREEMODEL_BASE_URL}" \
    FREEMODEL_MODEL="${FREEMODEL_MODEL}" \
    node api-server.js &
  WEB_PID=$!
  sleep 2
  echo "  ✅ Web Operator listo"
fi

# ── Proxy principal (OpenCode) ───────────────────────────
echo "  🚀 Iniciando proxy OpenCode en puerto $PROXY_PORT..."
cd /workspace/artifacts/opencode-ui

PORT="$PROXY_PORT" \
OPENCODE_INTERNAL_PORT="$OC_PORT" \
OPERATOR_PORT="$OPERATOR_PORT" \
API_SERVER_PORT="$OPERATOR_PORT" \
node proxy.mjs &
PROXY_PID=$!

# ── Proxy secundario (MiMo Code) ─────────────────────────
echo "  🚀 Iniciando proxy MiMo Code en puerto $MIMO_PROXY_PORT..."
PORT="$MIMO_PROXY_PORT" \
OPENCODE_INTERNAL_PORT="$MIMO_PORT" \
OPERATOR_PORT="$OPERATOR_PORT" \
API_SERVER_PORT="$OPERATOR_PORT" \
node proxy.mjs &
MIMO_PROXY_PID=$!

echo ""
echo "  ════════════════════════════════════════════════════════"
echo "  🌐 OpenCode Bridge en http://0.0.0.0:$PROXY_PORT"
echo "  🌐 MiMo Code Bridge en http://0.0.0.0:$MIMO_PROXY_PORT"
echo "  🖥️  VNC remoto en http://0.0.0.0:6080/vnc.html"
echo "  🤖 Web Operator en http://0.0.0.0:$OPERATOR_PORT"
echo "  ════════════════════════════════════════════════════════"

# Mantener vivo esperando ambos proxies
wait -n $PROXY_PID $MIMO_PROXY_PID
