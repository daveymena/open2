# 🔧 Solución: Frontend no se muestra en EasyPanel

## Problema Identificado

El frontend React no se estaba construyendo durante el despliegue en EasyPanel. El Dockerfile instalaba las dependencias pero **no ejecutaba el build de Vite** que genera los archivos estáticos HTML/CSS/JS necesarios.

## Cambios Realizados

### 1. **Dockerfile** - Agregado build del frontend
```dockerfile
# CONSTRUIR EL FRONTEND - Esto es crucial para que la UI se muestre
RUN cd artifacts/opencode-ui && npm run build
```

### 2. **proxy.mjs** - Configuración para servir archivos estáticos
- Ahora sirve los archivos desde `dist/public` (generados por Vite)
- Solo hace proxy a OpenCode para rutas específicas (`/api`, `/ws`, `/__opencode`)
- Sirve `index.html` como fallback para rutas del SPA React

## Cómo Redesplegar en EasyPanel

### Opción A: Push a GitHub y redesplegar
```bash
# 1. Hacer commit de los cambios
git add Dockerfile artifacts/opencode-ui/proxy.mjs
git commit -m "Fix: Construir frontend durante despliegue"
git push origin main

# 2. En EasyPanel:
# - Ve a tu servicio OpenCode
# - Click en "Rebuild" o "Redeploy"
# - Espera a que termine el build (puede tardar 5-10 min)
```

### Opción B: Reconstruir localmente primero (para probar)
```bash
# 1. Construir el frontend localmente
cd artifacts/opencode-ui
npm install
npm run build

# 2. Verificar que se generó dist/public
dir dist\public  # Windows
# Deberías ver: index.html, assets/, etc.

# 3. Probar localmente con Docker
cd ../..
docker build -t opencode-test .
docker run -p 3000:3000 opencode-test
```

## Verificar que Funciona

Después del redespliegue, visita tu URL de EasyPanel:
- Deberías ver la interfaz React (no un error de "Cannot GET /")
- Si ves un mensaje "Frontend no construido", el build falló
- Revisa los logs de construcción en EasyPanel

## Logs a Revisar en EasyPanel

Busca estas líneas en los logs de build:
```
✓ building...
✓ built in XXXms
```

Y al iniciar:
```
✦ Sirviendo frontend desde: /app/artifacts/opencode-ui/dist/public
✦ Modo: Sirviendo frontend + Proxy a OpenCode para /api, /ws
```

## Posibles Problemas Adicionales

### Si el build falla en EasyPanel:
1. **Memoria insuficiente**: Vite requiere ~1GB RAM para compilar
   - Aumenta el límite de memoria en `easypanel.yml` (actualmente 2048 MB)

2. **Timeout durante build**: 
   - El build de Vite puede tardar 3-5 minutos
   - Asegúrate que EasyPanel no tenga timeout muy corto

3. **Dependencias faltantes**:
   - Verifica que `node_modules` se instale correctamente
   - Mira los logs por errores de `npm install`

### Si el frontend carga pero no funciona:
1. **Rutas incorrectas**: Abre DevTools (F12) y revisa errores en Console
2. **Variables de entorno**: Verifica que las API keys estén configuradas en EasyPanel
3. **CORS**: Si hay errores de CORS, puede ser problema de proxy

## Estructura Correcta Después del Build

```
artifacts/opencode-ui/
├── dist/
│   └── public/           ← DEBE EXISTIR ESTO
│       ├── index.html
│       └── assets/
│           ├── index-[hash].js
│           └── index-[hash].css
├── src/
├── package.json
└── proxy.mjs
```

## Comando Rápido para Verificar

Si tienes acceso SSH al contenedor de EasyPanel:
```bash
ls -la /app/artifacts/opencode-ui/dist/public/
# Debe mostrar index.html y carpeta assets/
```

## Contacto

Si después de estos pasos sigue sin funcionar:
1. Copia los logs completos de build de EasyPanel
2. Verifica que el commit se haya subido correctamente a GitHub
3. Confirma que EasyPanel esté usando la rama correcta (main/master)
