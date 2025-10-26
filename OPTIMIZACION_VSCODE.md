# 🚀 Guía de Optimización de VS Code - Reducir Uso de RAM

## 📊 Problema Actual
VS Code está usando ~7GB de RAM con múltiples procesos ejecutándose.

## ✅ Soluciones Aplicadas Automáticamente

### 1. Configuración de Workspace Optimizada
Se ha actualizado `.vscode/settings.json` con:
- ✅ Exclusión de carpetas pesadas del file watcher
- ✅ Desactivación de Git auto-refresh
- ✅ Límite de 10 editores abiertos simultáneamente
- ✅ Minimap desactivado
- ✅ Telemetría desactivada

---

## 🔧 Soluciones Adicionales Manuales

### 2. Limpiar Caché de Flutter/Dart

```powershell
# Limpiar builds
cd "e:\Repos Git\Flutter-code-collector-app"
flutter clean

cd "e:\Repos Git\Flutter-code-collector-app\qr-manager\frontend"
flutter clean

cd "e:\Repos Git\Flutter-code-collector-app\test_app"
flutter clean

# Limpiar caché de pub
flutter pub cache repair
```

### 3. Cerrar Proyectos Innecesarios en VS Code

**Recomendación**: En lugar de tener todo el workspace abierto, abre solo la carpeta que estás editando:

```
❌ NO: Abrir e:\Repos Git\Flutter-code-collector-app (todo el monorepo)
✅ SÍ: Abrir e:\Repos Git\Flutter-code-collector-app\qr-manager\frontend
```

**Cómo hacerlo:**
1. `Ctrl + K, Ctrl + O` → "Open Folder"
2. Selecciona solo `qr-manager/frontend` o `test_app`
3. Cierra el workspace completo

### 4. Desactivar Extensiones Innecesarias

Abre configuración de extensiones (`Ctrl + Shift + X`) y desactiva:

- ❌ **Docker** (si no lo usas constantemente)
- ❌ **Remote - WSL** (si no lo necesitas ahora)
- ❌ **GitLens** (consume mucha RAM)
- ❌ **IntelliCode** (IA consume recursos)
- ❌ **Bracket Pair Colorizer** (nativo en VS Code ahora)
- ❌ **Auto Import** (puede ser pesado)

**Mantén activadas solo:**
- ✅ Flutter/Dart
- ✅ Básicas de desarrollo

### 5. Configurar Dart Analysis Server

Agrega en tu `settings.json` del usuario (no workspace):

**Windows:** `%APPDATA%\Code\User\settings.json`

```json
{
    "dart.analysisServerFolding": false,
    "dart.previewFlutterUiGuides": false,
    "dart.analysisExcludedFolders": [
        "**/node_modules",
        "**/.dart_tool",
        "**/build"
    ],
    "dart.maxLogLineLength": 2000,
    "dart.vmAdditionalArgs": [
        "--old_gen_heap_size=2048"
    ]
}
```

### 6. Aumentar Límite de Memoria del Dart Analysis Server

Crea/edita el archivo de análisis de Dart:

**Windows:** `%USERPROFILE%\.dartServer`

```
--max-old-space-size=2048
```

### 7. Reiniciar VS Code Regularmente

Cada 4-6 horas de uso continuo:

```powershell
# Guardar todo y cerrar VS Code, luego:
taskkill /F /IM Code.exe
```

### 8. Configurar Git para Mejor Rendimiento

```bash
# En cada proyecto:
cd "e:\Repos Git\Flutter-code-collector-app"
git config core.preloadIndex true
git config core.fscache true
git config gc.auto 256
```

### 9. Excluir Carpetas de Windows Defender

Windows Defender escanea archivos continuamente. Excluir carpetas de desarrollo:

1. Windows Security → Virus & threat protection
2. Manage settings → Exclusions
3. Agregar carpetas:
   - `e:\Repos Git\Flutter-code-collector-app`
   - `C:\Users\[TU_USUARIO]\AppData\Local\Pub\Cache`
   - `C:\src\flutter` (tu Flutter SDK)

### 10. Actualizar VS Code Settings (Usuario)

Presiona `Ctrl + ,` y busca estas opciones:

```
Files: Watcher Exclude → Agregar:
  - **/.dart_tool/**
  - **/build/**
  - **/node_modules/**

Search: Exclude → Agregar lo mismo

Editor: Minimap Enabled → ❌ Desactivar

Workbench > Editor: Limit → ✅ Activar (valor: 10)

Git: Auto Fetch → ❌ Desactivar
Git: Auto Refresh → ❌ Desactivar

Telemetry: Telemetry Level → off
```

---

## 📈 Monitoreo de Memoria

### Ver uso actual de VS Code:

```powershell
Get-Process Code | Measure-Object -Property WS -Sum | Select-Object @{Name="TotalRAM(GB)";Expression={[math]::Round($_.Sum/1GB,2)}}
```

### Ver procesos de Flutter/Dart:

```powershell
Get-Process | Where-Object {$_.ProcessName -like "*dart*" -or $_.ProcessName -like "*flutter*"} | Select-Object ProcessName, @{Name="RAM(MB)";Expression={[math]::Round($_.WS/1MB,2)}}
```

---

## 🎯 Objetivo de Optimización

| Antes | Después |
|-------|---------|
| ~7 GB | ~2-3 GB |

---

## 🔄 Comandos de Mantenimiento Regular

```powershell
# Ejecutar cada semana:

# 1. Limpiar builds de Flutter
flutter clean

# 2. Reparar cache de pub
flutter pub cache repair

# 3. Limpiar node_modules (si usas Node.js)
cd qr-manager/backend
rm -r node_modules
npm install

# 4. Reiniciar Dart Analysis Server en VS Code
# Ctrl + Shift + P → "Dart: Restart Analysis Server"
```

---

## ⚠️ Si Nada Funciona

### Última opción: Reinstalar VS Code Limpio

```powershell
# 1. Desinstalar VS Code
# 2. Eliminar configuraciones:
Remove-Item -Recurse -Force "$env:APPDATA\Code"
Remove-Item -Recurse -Force "$env:USERPROFILE\.vscode"

# 3. Reinstalar VS Code
# 4. Instalar SOLO extensiones esenciales:
#    - Flutter/Dart
#    - GitLens (opcional, pero consume RAM)
```

---

## 📚 Recursos Adicionales

- [VS Code Performance Tips](https://code.visualstudio.com/docs/getstarted/tips-and-tricks#_performance)
- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)
- [Dart VM Options](https://dart.dev/tools/dart-run#options)

---

## ✅ Checklist de Optimización

- [x] Configuración de workspace optimizada
- [ ] Cerrar proyectos innecesarios
- [ ] Desactivar extensiones pesadas
- [ ] Configurar Dart Analysis Server
- [ ] Excluir carpetas de Windows Defender
- [ ] Limpiar cache de Flutter
- [ ] Reiniciar VS Code
- [ ] Limitar memoria del Dart VM

**Después de aplicar estos cambios, el uso de RAM debería reducirse significativamente a 2-3 GB.** 🎉
