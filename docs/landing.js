(function () {
  const cfg = window.PEYMI_CONFIG || window.BIZMI_CONFIG || {};
  const appName = cfg.appName || "Peymii";
  const basePath = (cfg.basePath || "").replace(/\/+$/, "");
  const baseUrl = (cfg.publicBaseUrl || "https://bizmi.app").replace(/\/+$/, "");

  const playUrl =
    cfg.playStoreUrl ||
    "https://play.google.com/store/apps/details?id=com.example.bakery_shop_app";
  const appStoreUrl = (cfg.appStoreUrl || "").trim();
  const androidPackage = cfg.androidPackage || "com.example.bakery_shop_app";
  const deepLinkScheme = cfg.deepLinkScheme || "bizmi";
  const redirectDelayMs = cfg.redirectDelayMs ?? 1600;
  const tryOpenAppFirst = cfg.tryOpenAppFirst !== false;

  const reserved = new Set([
    "super-admin",
    "settings",
    "orders",
    "deals",
    "catalog",
    "www",
    ".well-known",
    "peymii",
    "docs",
  ]);

  const copy = {
    he: {
      brandTagline: "חנות ותורים באפליקציה",
      loading: "טוען חנות…",
      defaultTitle: "Peymii",
      defaultLead: "פתחו קישור חנות ששיתף העסק, או הורידו את האפליקציה.",
      downloadLead: "הורידו את אפליקציית Peymii כדי לצפות בחנות ולקבוע תורים.",
      deviceAndroid: "זיהינו Android — מעבירים ל-Google Play",
      deviceIos: "זיהינו iPhone / iPad — מעבירים ל-App Store",
      deviceDesktop: "פתחו מהטלפון להורדה אוטומטית, או בחרו חנות:",
      downloadAndroid: "הורדה מ-Google Play",
      downloadIos: "הורדה מ-App Store",
      openInApp: "פתיחה באפליקציה",
      redirecting: "מעבירים להורדת האפליקציה…",
      iosPending: "קישור App Store טרם הוגדר — ערכו APP_STORE_URL ב-config.js",
      configError: "חסר config.js — העתיקו מ-config.example.js וערכו מפתחות Supabase",
      loadError: "לא ניתן לטעון את החנות.",
      notFound: "החנות לא נמצאה",
      notFoundHint: "ייתכן שהקישור שגוי או שהחנות עדיין לא פעילה.",
      storeLabel: "חנות ב-Peymii",
    },
    en: {
      brandTagline: "Store & appointments in the app",
      loading: "Loading store…",
      defaultTitle: "Peymii",
      defaultLead: "Open a store link from a business, or download the app.",
      downloadLead: "Download Peymii to view this store and book appointments.",
      deviceAndroid: "Android detected — redirecting to Google Play",
      deviceIos: "iPhone / iPad detected — redirecting to App Store",
      deviceDesktop: "Open on your phone for automatic download:",
      downloadAndroid: "Get it on Google Play",
      downloadIos: "Download on the App Store",
      openInApp: "Open in app",
      redirecting: "Redirecting to download…",
      iosPending: "App Store link not set — edit APP_STORE_URL in config.js",
      configError: "Missing config.js — copy from config.example.js",
      loadError: "Could not load this store.",
      notFound: "Store not found",
      notFoundHint: "This link may be wrong or the store is not public yet.",
      storeLabel: "Store on Peymii",
    },
  };

  function lang() {
    const l = (navigator.language || "en").toLowerCase();
    return l.startsWith("he") ? "he" : "en";
  }

  function t(key) {
    return copy[lang()][key];
  }

  function restoreGithubPagesPath() {
    const saved = sessionStorage.getItem("peymii_path");
    if (!saved) return;
    sessionStorage.removeItem("peymii_path");
    if (location.pathname !== saved) {
      history.replaceState(null, "", saved + location.search);
    }
  }

  function slugFromPath() {
    restoreGithubPagesPath();
    let path = location.pathname;
    if (basePath && path.startsWith(basePath)) {
      path = path.slice(basePath.length) || "/";
    }
    const parts = path.replace(/^\/+|\/+$/g, "").split("/");
    const slug = (parts[0] || "").toLowerCase().replace(/[^a-z0-9-]/g, "");
    if (!slug || reserved.has(slug)) return null;
    return slug;
  }

  function detectPlatform() {
    const ua = navigator.userAgent || navigator.vendor || "";
    if (/android/i.test(ua)) return "android";
    const isIos =
      /iPad|iPhone|iPod/i.test(ua) ||
      (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1);
    if (isIos && !window.MSStream) return "ios";
    return "other";
  }

  function queryFlag(name) {
    return new URLSearchParams(location.search).get(name);
  }

  function setError(msg) {
    const el = document.getElementById("error");
    el.hidden = false;
    el.textContent = msg;
    hideLoader();
  }

  function hideLoader() {
    const loader = document.getElementById("loader");
    if (loader) loader.classList.add("done");
  }

  function highlightPlatform(platform) {
    const row = document.getElementById("platform-row");
    if (!row) return;
    row.hidden = false;
    row.querySelectorAll(".platform-chip").forEach((chip) => {
      chip.classList.toggle("active", chip.dataset.os === platform);
    });
  }

  function storeUrlFor(platform) {
    if (platform === "android") return playUrl;
    if (platform === "ios" && appStoreUrl && appStoreUrl !== "#") return appStoreUrl;
    return null;
  }

  function goToStore(platform) {
    const store = storeUrlFor(platform);
    if (store) window.location.replace(store);
  }

  function tryOpenAppThenStore(slug, platform) {
    const store = storeUrlFor(platform);
    if (!store) return;

    let left = false;
    const onVis = () => {
      if (document.hidden) left = true;
    };
    document.addEventListener("visibilitychange", onVis);

    if (platform === "android") {
      const fallback = encodeURIComponent(store);
      window.location.href =
        "intent://" +
        slug +
        "#Intent;scheme=" +
        deepLinkScheme +
        ";package=" +
        androidPackage +
        ";S.browser_fallback_url=" +
        fallback +
        ";end";
    } else if (platform === "ios") {
      window.location.href = deepLinkScheme + "://" + slug;
      setTimeout(() => {
        if (!left && !document.hidden) window.location.replace(store);
      }, 900);
    }

    setTimeout(() => {
      document.removeEventListener("visibilitychange", onVis);
      if (!left && !document.hidden && store) {
        window.location.replace(store);
      }
    }, redirectDelayMs);
  }

  function startMobileFlow(slug, platform) {
    const store = storeUrlFor(platform);
    const downloadOnly =
      queryFlag("download") === "1" || queryFlag("store") === "only";
    if (!store) return;
    if (downloadOnly) {
      goToStore(platform);
      return;
    }
    if (tryOpenAppFirst) tryOpenAppThenStore(slug, platform);
  }

  function setupDownloadUi(platform) {
    const hint = document.getElementById("device-hint");
    const primary = document.getElementById("download-primary");
    const secondary = document.getElementById("download-secondary");
    const openApp = document.getElementById("open-app");
    const status = document.getElementById("redirect-status");
    const redirectText = document.getElementById("redirect-text");
    const primaryIcon = document.getElementById("primary-icon");
    const primaryLabel = document.getElementById("primary-label");

    highlightPlatform(platform);

    if (platform === "android") {
      hint.textContent = t("deviceAndroid");
      primary.href = playUrl;
      primaryLabel.textContent = t("downloadAndroid");
      primaryIcon.textContent = "▶";
      primary.hidden = false;
      secondary.hidden = true;
      status.hidden = false;
      redirectText.textContent = t("redirecting");
    } else if (platform === "ios") {
      if (appStoreUrl && appStoreUrl !== "#") {
        hint.textContent = t("deviceIos");
        primary.href = appStoreUrl;
        primaryLabel.textContent = t("downloadIos");
        primaryIcon.textContent = "";
        primary.hidden = false;
        status.hidden = false;
        redirectText.textContent = t("redirecting");
      } else {
        hint.textContent = t("iosPending");
        primary.hidden = true;
        status.hidden = true;
      }
      secondary.hidden = true;
    } else {
      hint.textContent = t("deviceDesktop");
      primary.href = playUrl;
      primaryLabel.textContent = t("downloadAndroid");
      primaryIcon.textContent = "▶";
      primary.hidden = false;
      if (appStoreUrl && appStoreUrl !== "#") {
        secondary.href = appStoreUrl;
        secondary.textContent = t("downloadIos");
        secondary.hidden = false;
      } else {
        secondary.hidden = true;
      }
      status.hidden = true;
    }

    openApp.textContent = t("openInApp");
  }

  async function loadStore(slug) {
    const url = cfg.supabaseUrl;
    const key = cfg.supabaseAnonKey;
    if (!url || !key || key === "your_anon_key") {
      document.getElementById("store-name").textContent = t("storeLabel");
      setError(t("configError"));
      return;
    }

    const api =
      url.replace(/\/+$/, "") +
      "/rest/v1/businesses?select=business_name,description,slug&slug=eq." +
      encodeURIComponent(slug);

    try {
      const res = await fetch(api, {
        headers: { apikey: key, Authorization: "Bearer " + key },
      });
      if (!res.ok) {
        setError(t("loadError"));
        return;
      }
      const rows = await res.json();
      const store = rows[0];
      if (!store) {
        document.getElementById("store-name").textContent = t("notFound");
        setError(t("notFoundHint"));
        return;
      }
      document.getElementById("store-name").textContent = store.business_name;
      document.getElementById("store-slug").hidden = false;
      document.getElementById("store-slug").textContent = baseUrl + "/" + slug;
      document.getElementById("store-message").textContent = store.description
        ? store.description + " — " + t("downloadLead")
        : t("downloadLead");
      document.title = store.business_name + " — " + appName;
      hideLoader();
    } catch (_) {
      setError(t("loadError"));
    }
  }

  const slug = slugFromPath();
  const platform = detectPlatform();
  const smartLink = slug ? baseUrl + "/" + slug : baseUrl;

  document.documentElement.lang = lang() === "he" ? "he" : "en";
  document.documentElement.dir = lang() === "he" ? "rtl" : "ltr";

  const tagline = document.getElementById("brand-tagline");
  if (tagline) tagline.textContent = t("brandTagline");
  const foot = document.getElementById("footnote-domain");
  if (foot) {
    try {
      foot.textContent = new URL(baseUrl).host;
    } catch (_) {
      foot.textContent = baseUrl;
    }
  }

  document.getElementById("open-app").href = smartLink;
  setupDownloadUi(platform);

  if (!slug) {
    document.getElementById("store-name").textContent = t("defaultTitle");
    document.getElementById("store-message").textContent = t("defaultLead");
    hideLoader();
    return;
  }

  if (platform === "android" || platform === "ios") {
    startMobileFlow(slug, platform);
  }

  loadStore(slug);
})();
