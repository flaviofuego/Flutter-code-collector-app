# Configuración de Supabase para Flutter Barcode Scanner

## 📋 Resumen
Este proyecto ahora guarda automáticamente todos los códigos de barras escaneados en una base de datos Supabase en tiempo real.

## 🚀 Pasos de Configuración

### 1. Crear una cuenta en Supabase

1. Ve a [https://supabase.com](https://supabase.com)
2. Crea una cuenta gratuita
3. Crea un nuevo proyecto

### 2. Crear la tabla en Supabase

1. En el dashboard de tu proyecto, ve a **SQL Editor**
2. Copia y pega el siguiente SQL:

```sql
-- Crear la tabla para códigos de barras escaneados
CREATE TABLE scanned_barcodes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  code TEXT NOT NULL,
  type TEXT NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Crear índice para búsquedas rápidas por código
CREATE INDEX idx_scanned_barcodes_code ON scanned_barcodes(code);

-- Crear índice para búsquedas por fecha
CREATE INDEX idx_scanned_barcodes_timestamp ON scanned_barcodes(timestamp DESC);

-- Habilitar Row Level Security (RLS)
ALTER TABLE scanned_barcodes ENABLE ROW LEVEL SECURITY;

-- Política para permitir lectura a todos
CREATE POLICY "Permitir lectura a todos" 
  ON scanned_barcodes FOR SELECT 
  USING (true);

-- Política para permitir inserción a todos
CREATE POLICY "Permitir inserción a todos" 
  ON scanned_barcodes FOR INSERT 
  WITH CHECK (true);

-- Política para permitir actualización a todos
CREATE POLICY "Permitir actualización a todos" 
  ON scanned_barcodes FOR UPDATE 
  USING (true);

-- Política para permitir eliminación a todos
CREATE POLICY "Permitir eliminación a todos" 
  ON scanned_barcodes FOR DELETE 
  USING (true);
```

3. Haz clic en **Run** para ejecutar el SQL

### 3. Obtener las credenciales

1. Ve a **Settings** > **API** en el dashboard
2. Copia los siguientes valores:
   - **Project URL** (algo como `https://xxxxx.supabase.co`)
   - **anon/public key** (una cadena larga)

### 4. Configurar el proyecto Flutter

1. Abre el archivo `lib/config/supabase_config.dart`
2. Reemplaza los valores:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://xxxxx.supabase.co'; // Tu URL aquí
  static const String supabaseAnonKey = 'tu-anon-key-aqui'; // Tu anon key aquí
  
  static const String barcodesTable = 'scanned_barcodes';
}
```

### 5. Ejecutar la aplicación

```bash
flutter pub get
flutter run
```

## ✨ Características

### Guardado Automático
- Cada código escaneado se guarda automáticamente en Supabase
- No requiere acción manual del usuario

### Indicadores Visuales
En la tabla de códigos escaneados verás:
- 🔄 **Indicador de carga** (azul) mientras se guarda
- ✅ **Nube verde** cuando se guardó exitosamente
- ⚠️ **Nube naranja** si hubo un error

### Notificaciones
- ✓ Mensaje verde cuando se guarda correctamente
- ⚠ Mensaje naranja si hay un error

## 📊 Estructura de Datos

### Tabla: `scanned_barcodes`

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | UUID | ID único generado automáticamente |
| code | TEXT | El código de barras escaneado |
| type | TEXT | Tipo de código (EAN_13, QR_CODE, etc.) |
| timestamp | TIMESTAMPTZ | Fecha y hora del escaneo |
| created_at | TIMESTAMPTZ | Fecha de creación en la base de datos |

## 🔧 Servicios Disponibles

El archivo `services/supabase_service.dart` incluye:

### Métodos Principales
- `saveBarcode()` - Guardar un código
- `getAllBarcodes()` - Obtener todos los códigos
- `deleteBarcode(id)` - Eliminar un código
- `deleteAllBarcodes()` - Eliminar todos
- `searchByCode()` - Buscar códigos
- `getStatistics()` - Obtener estadísticas
- `testConnection()` - Verificar conexión
- `subscribeToChanges()` - Suscripción en tiempo real

## 🔒 Seguridad (Importante para Producción)

⚠️ **Las políticas actuales permiten acceso completo a todos los usuarios**

Para producción, deberías:

1. Implementar autenticación de usuarios en Supabase
2. Modificar las políticas RLS para que solo los usuarios autenticados puedan acceder a sus propios datos:

```sql
-- Ejemplo de política más segura (requiere autenticación)
CREATE POLICY "Los usuarios solo ven sus propios códigos" 
  ON scanned_barcodes FOR SELECT 
  USING (auth.uid() = user_id);
```

3. Agregar campo `user_id` a la tabla
4. Implementar login en la app

## 📱 Verificar los Datos

Para ver los códigos guardados:

1. Ve al dashboard de Supabase
2. Selecciona **Table Editor**
3. Haz clic en la tabla `scanned_barcodes`
4. Verás todos los códigos escaneados en tiempo real

## 🐛 Solución de Problemas

### Error: "Invalid API credentials"
- Verifica que la URL y la anon key estén correctas
- Asegúrate de no tener espacios en las credenciales

### Error: "Permission denied"
- Verifica que las políticas RLS estén configuradas
- Asegúrate de haber ejecutado todo el SQL de creación

### No se guardan los códigos
- Verifica tu conexión a internet
- Revisa los logs en el terminal de Flutter
- Verifica que la tabla exista en Supabase

### Ver logs de errores
Los errores se imprimen en la consola y se muestran como SnackBars en la app.

## 📦 Dependencias Agregadas

```yaml
dependencies:
  supabase_flutter: ^2.8.1
  path: ^1.9.0
```

## 🎯 Próximas Mejoras Sugeridas

- [ ] Implementar autenticación de usuarios
- [ ] Sincronización bidireccional (cargar códigos guardados al abrir la app)
- [ ] Modo offline (guardar localmente y sincronizar cuando hay conexión)
- [ ] Exportar directamente desde Supabase
- [ ] Dashboard de estadísticas
- [ ] Filtros y búsqueda en tiempo real

## 📄 Archivos Creados/Modificados

### Nuevos archivos:
- `lib/config/supabase_config.dart` - Configuración
- `lib/services/supabase_service.dart` - Servicio de Supabase
- `SUPABASE_SETUP.md` - Este archivo

### Archivos modificados:
- `pubspec.yaml` - Dependencias
- `lib/main.dart` - Integración con Supabase

## 💡 Consejo

Mantén tus credenciales de Supabase seguras. No las compartas en repositorios públicos. Considera usar variables de entorno o archivos de configuración privados para producción.

## 📞 Soporte

- Documentación oficial de Supabase: [https://supabase.com/docs](https://supabase.com/docs)
- Flutter y Supabase: [https://supabase.com/docs/guides/getting-started/tutorials/with-flutter](https://supabase.com/docs/guides/getting-started/tutorials/with-flutter)
