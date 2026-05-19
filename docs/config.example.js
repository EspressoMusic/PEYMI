// העתיקו ל-config.js לפני פריסה (או הריצו tools/generate_peymii_config.ps1)
window.PEYMI_CONFIG = {
  appName: "Peymii",
  publicBaseUrl: "https://bizmi.app",
  // אם GitHub Pages מפרסם מ-repo: https://espressomusic.github.io/PEYMI/
  basePath: "",

  supabaseUrl: "https://YOUR_PROJECT.supabase.co",
  supabaseAnonKey: "YOUR_SUPABASE_ANON_KEY",

  playStoreUrl:
    "https://play.google.com/store/apps/details?id=com.example.bakery_shop_app",
  appStoreUrl: "",
  androidPackage: "com.example.bakery_shop_app",
  deepLinkScheme: "bizmi",

  tryOpenAppFirst: true,
  redirectDelayMs: 1600,
};
