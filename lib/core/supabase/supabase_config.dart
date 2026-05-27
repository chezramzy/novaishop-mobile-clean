class SupabaseConfig {
  const SupabaseConfig._();

  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://dkcfctxwfxihgirzhoig.supabase.co',
  );

  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_OI_sAg7HhhgXgppcCc6jhA_OdMGrlXe',
  );

  static const mediaBucket = String.fromEnvironment(
    'SUPABASE_MEDIA_BUCKET',
    defaultValue: 'novaishop-media',
  );
}
