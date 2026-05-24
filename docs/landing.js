(function () {
  const cfg = window.PEYMI_CONFIG || window.BIZMI_CONFIG || {};

  function detectGitHubPages() {
    if (!location.hostname.endsWith("github.io")) return null;
    const parts = location.pathname.split("/").filter(Boolean);
    if (parts.length === 0) return { basePath: "", baseUrl: location.origin.replace(/\/+$/, "") };
    const repo = parts[0];
    return {
      basePath: "/" + repo,
      baseUrl: location.origin.replace(/\/+$/, "") + "/" + repo,
    };
  }

  const gh = detectGitHubPages();
  const appName = cfg.appName || "Bizmi";
  let basePath = (cfg.basePath != null ? cfg.basePath : gh?.basePath || "").replace(/\/+$/, "");
  let baseUrl = (cfg.publicBaseUrl || gh?.baseUrl || "https://bizmi.app").replace(/\/+$/, "");
  const testingMode = cfg.testingMode !== false;
  const apkUrl = (cfg.apkDownloadUrl || cfg.testApkUrl || "").trim();

  const playUrl = (cfg.playStoreUrl || "").trim();
  const appStoreUrl = (cfg.appStoreUrl || "").trim();
  const androidPackage = cfg.androidPackage || "com.example.bakery_shop_app";
  const deepLinkScheme = cfg.deepLinkScheme || "bizmi";
  const redirectDelayMs = cfg.redirectDelayMs ?? 1600;
  const tryOpenAppFirst = cfg.tryOpenAppFirst === true;
  const isWebMode =
    queryFlag("web") === "1" ||
    queryFlag("browse") === "1" ||
    location.pathname.endsWith("/web");

  let cachedProducts = [];

  function queryFlag(name) {
    return new URLSearchParams(location.search).get(name);
  }

  const reserved = new Set([
    "super-admin",
    "settings",
    "orders",
    "deals",
    "catalog",
    "www",
    ".well-known",
    "peymii",
    "peymi",
    "docs",
  ]);

  if (basePath) {
    const repoSeg = basePath.replace(/^\//, "").toLowerCase();
    if (repoSeg) reserved.add(repoSeg);
  }

  const copy = {
    he: {
      brandTagline: "חנות ותורים באפליקציה",
      loading: "טוען חנות…",
      testingBanner: "Bizmi בבדיקות",
      testingLead: "הורידו את האפליקציה או צפו בחנות בדפדפן.",
      apkButton: "הורדת APK לבדיקה (Android)",
      apkUnavailable: "קישור ההורדה עדיין לא זמין.",
      openingApp: "מנסים לפתוח באפליקציה…",
      openInApp: "פתיחה באפליקציה",
      configError: "חסר config.js — העתיקו מ-config.example.js",
      loadError: "לא ניתן לטעון את החנות.",
      notFound: "החנות לא נמצאה",
      notFoundHint: "ייתכן שהקישור שגוי או שהחנות עדיין לא פעילה.",
      storeLabel: "חנות ב-Bizmi",
      downloadLead: "בחרו: הורדת האפליקציה או המשך בגרסת אתר.",
      continueOnWeb: "המשך בגרסת אתר",
      webModeHint: "גרסת אתר — להזמנה מלאה הורידו את האפליקציה.",
      browseInBrowser: "צפייה בחנות בדפדפן",
      browserCatalogTitle: "מוצרים",
      browserNoProducts: "אין מוצרים להצגה כרגע — הורידו את האפליקציה לחוויה המלאה.",
      downloadApp: "הורדת האפליקציה",
      deviceAndroid: "Android — Google Play",
      deviceIos: "iPhone / iPad — App Store",
      deviceDesktop: "הורידו את האפליקציה:",
      downloadAndroid: "Google Play",
      downloadIos: "App Store",
      redirecting: "מעבירים לחנות…",
    },
    en: {
      brandTagline: "Store & appointments in the app",
      loading: "Loading store…",
      testingBanner: "Bizmi is in testing",
      testingLead: "Download the app or browse the store in your browser.",
      apkButton: "Download Android Test APK",
      apkUnavailable: "Download link is not available yet.",
      openingApp: "Trying to open the app…",
      openInApp: "Open in app",
      configError: "Missing config.js — copy from config.example.js",
      loadError: "Could not load this store.",
      notFound: "Store not found",
      notFoundHint: "This link may be wrong or the store is not public yet.",
      storeLabel: "Store on Bizmi",
      downloadLead: "Choose: download the app or continue in the web version.",
      continueOnWeb: "Continue on web",
      webModeHint: "Web version — download the app to order.",
      browseInBrowser: "Browse store in browser",
      browserCatalogTitle: "Products",
      browserNoProducts: "No products to show yet — download the app for the full experience.",
      downloadApp: "Download app",
      deviceAndroid: "Android — Google Play",
      deviceIos: "iPhone / iPad — App Store",
      deviceDesktop: "Download the app:",
      downloadAndroid: "Google Play",
      downloadIos: "App Store",
      redirecting: "Redirecting to download…",
    },
  };

  function lang() {
    const q = new URLSearchParams(location.search).get("lang");
    if (q === "en") return "en";
    if (q === "he") return "he";
    if (cfg.defaultLang === "en") return "en";
    return "he";
  }

  function t(key) {
    return copy[lang()][key];
  }

  function restoreGithubPagesPath() {
    const saved = sessionStorage.getItem("peymii_path");
    if (!saved) return;
    sessionStorage.removeItem("peymii_path");
    const savedPath = saved.split("?")[0].split("#")[0];
    if (location.pathname !== savedPath) {
      history.replaceState(null, "", saved);
    }
  }

  function ensureBaseHref() {
    if (!basePath) return;
    let el = document.querySelector("base[data-peymii-base]");
    if (!el) {
      el = document.createElement("base");
      el.setAttribute("data-peymii-base", "1");
      document.head.insertBefore(el, document.head.firstChild);
    }
    el.href = basePath + "/";
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

  function escapeHtml(text) {
    return String(text || "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function showBrowserCatalog(products) {
    const section = document.getElementById("browser-catalog");
    const card = document.getElementById("app");
    if (!section) return;

    const items = products || [];
    if (!items.length) {
      section.innerHTML =
        '<p class="catalog-title">' +
        escapeHtml(t("browserCatalogTitle")) +
        '</p><p class="catalog-empty">' +
        escapeHtml(t("browserNoProducts")) +
        "</p>";
    } else {
      section.innerHTML =
        '<p class="catalog-title">' +
        escapeHtml(t("browserCatalogTitle")) +
        "</p>" +
        items
          .map(function (p) {
            var price = Math.round(Number(p.price) || 0);
            var desc = p.description
              ? '<p class="catalog-desc">' + escapeHtml(p.description) + "</p>"
              : "";
            return (
              '<article class="catalog-item"><div class="catalog-item-body"><h3>' +
              escapeHtml(p.name) +
              "</h3>" +
              desc +
              '</div><strong class="catalog-price">₪' +
              price +
              "</strong></article>"
            );
          })
          .join("");
    }

    section.hidden = false;
    if (card) card.classList.add("card--wide");
  }

  function enterWebMode(products) {
    cachedProducts = products || cachedProducts;
    const gateway = document.getElementById("actions-testing");
    const storeActions = document.getElementById("actions-store");
    const banner = document.getElementById("testing-banner");
    const webBar = document.getElementById("web-download-bar");
    if (gateway) gateway.hidden = true;
    if (storeActions) storeActions.hidden = true;
    if (banner) banner.hidden = true;
    const msg = document.getElementById("store-message");
    if (msg) msg.textContent = t("webModeHint");
    showBrowserCatalog(cachedProducts);
    if (webBar) webBar.hidden = false;
  }

  function goToWebVersion() {
    const url = new URL(location.href);
    url.searchParams.set("web", "1");
    history.replaceState(null, "", url.toString());
    enterWebMode(cachedProducts);
  }

  function wireContinueWebButton() {
    function attach(id) {
      const btn = document.getElementById(id);
      if (!btn) return;
      btn.hidden = false;
      btn.textContent = t("continueOnWeb");
      btn.classList.add("btn-secondary");
      btn.onclick = function () {
        goToWebVersion();
      };
    }
    attach("continue-web");
    attach("browse-browser-store");
  }

  function wireBrowseButton(products) {
    cachedProducts = products || cachedProducts;
    wireContinueWebButton();
    if (isWebMode || queryFlag("web") === "1" || queryFlag("browse") === "1") {
      enterWebMode(cachedProducts);
    }
  }

  async function fetchProducts(businessId) {
    var url = cfg.supabaseUrl;
    var key = cfg.supabaseAnonKey;
    if (!url || !key || !businessId) return [];
    var api =
      url.replace(/\/+$/, "") +
      "/rest/v1/products?select=name,price,description,image_url&business_id=eq." +
      encodeURIComponent(businessId) +
      "&is_active=eq.true&order=created_at.desc";
    try {
      var res = await fetch(api, {
        headers: { apikey: key, Authorization: "Bearer " + key },
      });
      if (!res.ok) return [];
      return await res.json();
    } catch (_) {
      return [];
    }
  }

  /** Deep link the Flutter app handles (bizmi://shiki). Not the GitHub Pages URL. */
  function customSchemeLink(slug) {
    return slug ? deepLinkScheme + "://" + slug : deepLinkScheme + "://";
  }

  function androidAppIntent(slug, httpsFallback) {
    var tail =
      "scheme=" +
      deepLinkScheme +
      ";package=" +
      androidPackage +
      (httpsFallback
        ? ";S.browser_fallback_url=" + encodeURIComponent(httpsFallback)
        : "") +
      ";end";
    return "intent://" + slug + "#Intent;" + tail;
  }

  function openInApp(slug, platform) {
    if (!slug) return;

    const status = document.getElementById("open-app-status");
    if (status) {
      status.hidden = false;
      status.textContent = t("openingApp");
    }

    const httpsStore = baseUrl.replace(/\/+$/, "") + "/" + slug;

    if (platform === "android") {
      window.location.href = androidAppIntent(
        slug,
        testingMode ? "" : httpsStore
      );
    } else {
      window.location.href = customSchemeLink(slug);
    }

    setTimeout(() => {
      if (status) status.hidden = true;
    }, 2000);
  }

  function wireOpenInAppButton(buttonId, slug, platform) {
    const el = document.getElementById(buttonId);
    if (!el) return;

    el.textContent = t("openInApp");

    if (!slug) {
      el.removeAttribute("href");
      el.onclick = null;
      return;
    }

    el.href = customSchemeLink(slug);
    el.onclick = function (e) {
      e.preventDefault();
      openInApp(slug, platform);
      return false;
    };
  }

  function tryOpenAppOnly(slug, platform) {
    if (!tryOpenAppFirst || !slug) return;
    openInApp(slug, platform);
  }

  function setupTestingUi(slug, platform) {
    document.getElementById("actions-testing").hidden = false;
    document.getElementById("actions-store").hidden = true;

    const banner = document.getElementById("testing-banner");
    banner.hidden = false;
    banner.textContent = t("testingBanner");

    const msg = document.getElementById("store-message");
    if (slug) {
      msg.textContent = t("testingLead");
    } else {
      document.getElementById("store-name").textContent = appName;
      msg.textContent = t("testingLead");
      hideLoader();
    }

    const apkBtn = document.getElementById("apk-download");
    const apkMissing = document.getElementById("apk-unavailable");

    if (apkUrl && apkUrl !== "#") {
      apkBtn.href = apkUrl;
      apkBtn.textContent = t("apkButton");
      apkBtn.hidden = false;
      apkBtn.setAttribute("download", "bizmi-test.apk");
      apkBtn.target = "_blank";
      apkBtn.rel = "noopener noreferrer";
      apkBtn.classList.add("btn-apk");
      apkBtn.removeAttribute("aria-disabled");
      apkMissing.hidden = true;
    } else {
      apkBtn.hidden = true;
      apkMissing.hidden = false;
      apkMissing.textContent = t("apkUnavailable");
    }

    wireOpenInAppButton("open-app", slug, platform);
    if (slug) wireContinueWebButton();

    const webApk = document.getElementById("web-apk-link");
    if (webApk && apkUrl && apkUrl !== "#") {
      webApk.href = apkUrl;
      webApk.textContent = t("apkButton");
      webApk.hidden = false;
    }
  }

  function storeUrlFor(platform) {
    if (platform === "android" && playUrl) return playUrl;
    if (platform === "ios" && appStoreUrl && appStoreUrl !== "#") return appStoreUrl;
    return null;
  }

  function tryOpenAppThenStore(slug, platform) {
    const store = storeUrlFor(platform);
    if (!store) {
      tryOpenAppOnly(slug, platform);
      return;
    }

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

  function setupStoreUi(platform, slug) {
    document.getElementById("actions-testing").hidden = true;
    document.getElementById("actions-store").hidden = false;

    const hint = document.getElementById("device-hint");
    const primary = document.getElementById("download-primary");
    const secondary = document.getElementById("download-secondary");
    const status = document.getElementById("redirect-status");
    const redirectText = document.getElementById("redirect-text");

    wireOpenInAppButton("open-app-store", slug, platform);

    if (platform === "android" && playUrl) {
      hint.textContent = t("deviceAndroid");
      primary.href = playUrl;
      primary.textContent = t("downloadApp");
      primary.hidden = false;
      secondary.hidden = true;
      status.hidden = true;
    } else if (platform === "ios" && appStoreUrl) {
      hint.textContent = t("deviceIos");
      primary.href = appStoreUrl;
      primary.textContent = t("downloadApp");
      primary.hidden = false;
      secondary.hidden = true;
      status.hidden = true;
    } else {
      hint.textContent = t("deviceDesktop");
      primary.hidden = !playUrl;
      if (playUrl) {
        primary.href = playUrl;
        primary.textContent = t("downloadAndroid");
      }
      secondary.hidden = !appStoreUrl;
      if (appStoreUrl) {
        secondary.href = appStoreUrl;
        secondary.textContent = t("downloadIos");
      }
      status.hidden = true;
    }
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
      "/rest/v1/businesses?select=id,business_name,description,slug&slug=eq." +
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
      document.getElementById("store-message").textContent = t("downloadLead");
      document.title = store.business_name + " — " + appName;
      hideLoader();

      const products = await fetchProducts(store.id);
      wireBrowseButton(products);
    } catch (_) {
      setError(t("loadError"));
    }
  }

  const slug = slugFromPath();
  const platform = detectPlatform();

  document.documentElement.lang = lang() === "he" ? "he" : "en";
  document.documentElement.dir = lang() === "he" ? "rtl" : "ltr";
  ensureBaseHref();

  const badge = document.getElementById("brand-badge");
  if (badge) badge.textContent = appName;
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

  if (testingMode) {
    setupTestingUi(slug, platform);
    if (slug) loadStore(slug);
    else hideLoader();
  } else {
    setupStoreUi(platform, slug);
    if (slug) loadStore(slug);
    else {
      document.getElementById("store-name").textContent = appName;
      document.getElementById("store-message").textContent = t("downloadLead");
      hideLoader();
    }
  }
})();
