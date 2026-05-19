(function () {
  const cfg = window.BIZMI_CONFIG || {};
  const baseUrl = (cfg.publicBaseUrl || "https://bizmi.app").replace(/\/+$/, "");
  const playUrl =
    cfg.playStoreUrl ||
    "https://play.google.com/store/apps/details?id=com.example.bakery_shop_app";
  const appStoreUrl = (cfg.appStoreUrl || "").trim();
  const androidPackage =
    cfg.androidPackage || "com.example.bakery_shop_app";
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
  ]);

  const copy = {
    he: {
      loading: "טוען חנות…",
      defaultTitle: "Bizmi",
      defaultLead: "פתחו קישור חנות ששיתף העסק, או הורידו את האפליקציה.",
      downloadLead: "הורידו את אפליקציית Bizmi כדי לצפות בחנות ולקבוע תורים.",
      deviceAndroid: "זיהינו Android — מעבירים ל-Google Play",
      deviceIos: "זיהינו iPhone / iPad — מעבירים ל-App Store",
      deviceDesktop: "פתחו מהטלפון להורדה אוטומטית, או בחרו חנות:",
      downloadAndroid: "הורדה מ-Google Play",
      downloadIos: "הורדה מ-App Store",
      openInApp: "פתיחה באפליקציה",
      redirecting: "מעבירים להורדת האפליקציה…",
      iosPending: "קישור App Store טרם הוגדר — עדכנו APP_STORE_URL בפריסה.",
      configError: "חסר config.js — הריצו tools/generate_bizmi_config.ps1",
      loadError: "לא ניתן לטעון את החנות.",
      notFound: "החנות לא נמצאה",
      notFoundHint: "ייתכן שהקישור שגוי או שהחנות עדיין לא פעילה.",
      storeOnBizmi: "חנות ב-Bizmi",
    },
    en: {
      loading: "Loading store…",
      defaultTitle: "Bizmi",
      defaultLead: "Open a store link shared by a business, or download the app.",
      downloadLead: "Download the Bizmi app to view this store and book appointments.",
      deviceAndroid: "Android detected — redirecting to Google Play",
      deviceIos: "iPhone / iPad detected — redirecting to App Store",
      deviceDesktop: "Open on your phone for automatic download, or choose a store:",
      downloadAndroid: "Get it on Google Play",
      downloadIos: "Download on the App Store",
      openInApp: "Open in app",
      redirecting: "Redirecting to download the app…",
      iosPending: "App Store link not configured yet (APP_STORE_URL).",
      configError: "Missing config.js — run tools/generate_bizmi_config.ps1",
      loadError: "Could not load this store.",
      notFound: "Store not found",
      notFoundHint: "This link may be wrong or the store is not public yet.",
      storeOnBizmi: "Store on Bizmi",
    },
  };

  function lang() {
    const l = (navigator.language || "en").toLowerCase();
    return l.startsWith("he") ? "he" : "en";
  }

  function t(key) {
    return copy[lang()][key];
  }

  function slugFromPath() {
    const parts = location.pathname.replace(/^\/+|\/+$/g, "").split("/");
    const slug = (parts[0] || "").toLowerCase().replace(/[^a-z0-9-]/g, "");
    if (!slug || reserved.has(slug)) return null;
    return slug;
  }

  /** @returns {'android'|'ios'|'other'} */
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
      const intent =
        "intent://" +
        slug +
        "#Intent;scheme=bizmi;package=" +
        androidPackage +
        ";S.browser_fallback_url=" +
        fallback +
        ";end";
      window.location.href = intent;
    } else if (platform === "ios") {
      window.location.href = "bizmi://" + slug;
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

    if (tryOpenAppFirst) {
      tryOpenAppThenStore(slug, platform);
    }
  }

  function setupDownloadUi(platform) {
    const hint = document.getElementById("device-hint");
    const primary = document.getElementById("download-primary");
    const secondary = document.getElementById("download-secondary");
    const openApp = document.getElementById("open-app");
    const status = document.getElementById("redirect-status");

    if (platform === "android") {
      hint.textContent = t("deviceAndroid");
      primary.href = playUrl;
      primary.textContent = t("downloadAndroid");
      primary.hidden = false;
      secondary.hidden = true;
      status.hidden = false;
      status.textContent = t("redirecting");
    } else if (platform === "ios") {
      if (appStoreUrl && appStoreUrl !== "#") {
        hint.textContent = t("deviceIos");
        primary.href = appStoreUrl;
        primary.textContent = t("downloadIos");
        primary.hidden = false;
        status.hidden = false;
        status.textContent = t("redirecting");
      } else {
        hint.textContent = t("iosPending");
        primary.hidden = true;
        status.hidden = true;
      }
      secondary.hidden = true;
    } else {
      hint.textContent = t("deviceDesktop");
      primary.href = playUrl;
      primary.textContent = t("downloadAndroid");
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
    if (!url || !key) {
      document.getElementById("store-name").textContent = t("storeOnBizmi");
      setError(t("configError"));
      return;
    }

    const api =
      url.replace(/\/+$/, "") +
      "/rest/v1/businesses?select=business_name,description,slug,is_active,subscription_status&slug=eq." +
      encodeURIComponent(slug);

    try {
      const res = await fetch(api, {
        headers: {
          apikey: key,
          Authorization: "Bearer " + key,
        },
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
      document.title = store.business_name + " — Bizmi";
    } catch (_) {
      setError(t("loadError"));
    }
  }

  const slug = slugFromPath();
  const platform = detectPlatform();
  const smartLink = slug ? baseUrl + "/" + slug : baseUrl;

  document.documentElement.lang = lang() === "he" ? "he" : "en";
  document.documentElement.dir = lang() === "he" ? "rtl" : "ltr";

  document.getElementById("open-app").href = smartLink;
  setupDownloadUi(platform);

  if (!slug) {
    document.getElementById("store-name").textContent = t("defaultTitle");
    document.getElementById("store-message").textContent = t("defaultLead");
    return;
  }

  // Mobile: redirect immediately (do not wait for Supabase).
  if (platform === "android" || platform === "ios") {
    startMobileFlow(slug, platform);
  }

  loadStore(slug);
})();
