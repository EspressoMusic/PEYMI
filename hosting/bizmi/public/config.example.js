// Copy to config.js OR run: .\tools\generate_bizmi_config.ps1 (reads .env)
window.BIZMI_CONFIG = {
  publicBaseUrl: "https://bizmi.app",
  supabaseUrl: "https://YOUR_PROJECT.supabase.co",
  supabaseAnonKey: "YOUR_SUPABASE_ANON_KEY",

  // App download — set PLAY_STORE_URL / APP_STORE_URL in .env when published
  playStoreUrl:
    "https://play.google.com/store/apps/details?id=com.example.bakery_shop_app",
  appStoreUrl: "https://apps.apple.com/app/id0000000000",
  androidPackage: "com.example.bakery_shop_app",

  // Try app deep link first; if missing, redirect to the right store (Android/iOS)
  tryOpenAppFirst: true,
  redirectDelayMs: 1600,
};
