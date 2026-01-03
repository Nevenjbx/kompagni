class EnvironmentConfig {
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://192.168.1.111:3000',
  );

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://kgdaaumpgtcdhkwomzdk.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtnZGFhdW1wZ3RjZGhrd29temRrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzMjY3NTcsImV4cCI6MjA3ODY4Njc1N30.AOG6k2ZA5zX9bty-8bYZDj7iLzJGf7eGR4ZFZ07cDAY',
  );
}
