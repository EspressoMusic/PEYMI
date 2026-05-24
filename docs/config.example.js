// Copy to docs/config.js (gitignored) and fill from .env, or run:
//   .\tools\generate_peymii_config.ps1
window.PEYMI_CONFIG = {
  appName: "Bizmi",
  publicBaseUrl: "https://your-user.github.io/PEYMI",
  basePath: "/PEYMI",
  supabaseUrl: "https://YOUR_PROJECT.supabase.co",
  supabaseAnonKey: "YOUR_SUPABASE_ANON_KEY",
  testingMode: true,
  apkDownloadUrl: "",
  playStoreUrl: "",
  appStoreUrl: "",
  androidPackage: "com.example.bakery_shop_app",
  deepLinkScheme: "bizmi",
  defaultLang: "he",
  tryOpenAppFirst: false,
  redirectDelayMs: 1600,
};
