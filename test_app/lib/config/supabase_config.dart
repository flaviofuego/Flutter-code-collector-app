// Configuración de Supabase
// 
// IMPORTANTE: Reemplaza estos valores con tus credenciales de Supabase
// 1. Ve a https://supabase.com/dashboard
// 2. Selecciona tu proyecto
// 3. Ve a Settings > API
// 4. Copia la URL y la anon/public key

class SupabaseConfig {
  // TODO: Reemplazar con tu URL de Supabase
  static const String supabaseUrl = 'https://gtjbbiexfnqqbdqebzgy.supabase.co';
  
  // TODO: Reemplazar con tu anon key de Supabase
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd0amJiaWV4Zm5xcWJkcWViemd5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEzNTMxMDgsImV4cCI6MjA3NjkyOTEwOH0.aap42QTwRmooHdqB26Gdj99AjZKNBiof2D9co4e_c-o';
  
  // Nombre de la tabla en Supabase
  static const String barcodesTable = 'scanned_barcodes';
}

/// INSTRUCCIONES PARA CREAR LA TABLA EN SUPABASE:
/// 
/// 1. Ve a tu proyecto en Supabase Dashboard
/// 2. Ve a la sección SQL Editor
/// 3. Ejecuta el siguiente SQL:
/// 
/// ```sql
/// -- Crear la tabla para códigos de barras escaneados
/// CREATE TABLE scanned_barcodes (
///   id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
///   code TEXT NOT NULL,
///   type TEXT NOT NULL,
///   timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
///   created_at TIMESTAMPTZ DEFAULT NOW()
/// );
/// 
/// -- Crear índice para búsquedas rápidas por código
/// CREATE INDEX idx_scanned_barcodes_code ON scanned_barcodes(code);
/// 
/// -- Crear índice para búsquedas por fecha
/// CREATE INDEX idx_scanned_barcodes_timestamp ON scanned_barcodes(timestamp DESC);
/// 
/// -- Habilitar Row Level Security (RLS)
/// ALTER TABLE scanned_barcodes ENABLE ROW LEVEL SECURITY;
/// 
/// -- Política para permitir lectura a todos (ajusta según tus necesidades)
/// CREATE POLICY "Permitir lectura a todos" 
///   ON scanned_barcodes FOR SELECT 
///   USING (true);
/// 
/// -- Política para permitir inserción a todos (ajusta según tus necesidades)
/// CREATE POLICY "Permitir inserción a todos" 
///   ON scanned_barcodes FOR INSERT 
///   WITH CHECK (true);
/// 
/// -- Política para permitir actualización a todos (ajusta según tus necesidades)
/// CREATE POLICY "Permitir actualización a todos" 
///   ON scanned_barcodes FOR UPDATE 
///   USING (true);
/// 
/// -- Política para permitir eliminación a todos (ajusta según tus necesidades)
/// CREATE POLICY "Permitir eliminación a todos" 
///   ON scanned_barcodes FOR DELETE 
///   USING (true);
/// ```
/// 
/// 4. Ajusta las políticas de seguridad según tus necesidades
/// 5. Para producción, considera implementar autenticación de usuarios
