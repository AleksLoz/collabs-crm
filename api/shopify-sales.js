// Vercel serverless function: GET /api/shopify-sales
//
// Returns the last 12 months of Shopify sales (total, net, orders) for the
// Collabs dashboard tile. It runs on the server because a Shopify Admin API
// credential must never be shipped to the browser. Only signed-in Collabs
// users can call it: the caller's Supabase session token is verified first.
//
// Configure in Vercel -> Project -> Settings -> Environment Variables:
//   SHOPIFY_ACCESS_TOKEN                      Admin API token with read_reports
//   -- or --
//   SHOPIFY_CLIENT_ID + SHOPIFY_CLIENT_SECRET (app credentials; a short-lived
//                                              token is requested automatically)
// Optional: SHOPIFY_SHOP, SHOPIFY_API_VERSION.

const SHOP = process.env.SHOPIFY_SHOP || "b15dcb-90.myshopify.com";
const API_VERSION = process.env.SHOPIFY_API_VERSION || "2026-04";
// Public values (same as config.js); the key is publishable by design.
const SUPABASE_URL = process.env.SUPABASE_URL || "https://hpduirwdffimkhjehyds.supabase.co";
const SUPABASE_KEY = process.env.SUPABASE_PUBLISHABLE_KEY || "sb_publishable_9-QdIoaDjQK5AuUihnGsxA_ju7a8ERY";

let cachedToken = { value: null, expires: 0 };

async function adminToken() {
  if (process.env.SHOPIFY_ACCESS_TOKEN) return process.env.SHOPIFY_ACCESS_TOKEN;
  const id = process.env.SHOPIFY_CLIENT_ID;
  const secret = process.env.SHOPIFY_CLIENT_SECRET;
  if (!id || !secret) return null;
  if (cachedToken.value && Date.now() < cachedToken.expires) return cachedToken.value;
  const r = await fetch(`https://${SHOP}/admin/oauth/access_token`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ client_id: id, client_secret: secret, grant_type: "client_credentials" })
  });
  if (!r.ok) throw new Error("Shopify token request failed (" + r.status + ")");
  const j = await r.json();
  cachedToken = { value: j.access_token, expires: Date.now() + Math.max(60, (j.expires_in || 3600) - 120) * 1000 };
  return cachedToken.value;
}

module.exports = async function handler(req, res) {
  const send = (code, body) => {
    res.setHeader("Content-Type", "application/json");
    res.status(code).send(JSON.stringify(body));
  };
  try {
    const auth = req.headers.authorization || "";
    if (!auth.startsWith("Bearer ")) return send(401, { error: "Sign in first" });
    const who = await fetch(SUPABASE_URL + "/auth/v1/user", { headers: { apikey: SUPABASE_KEY, Authorization: auth } });
    if (!who.ok) return send(401, { error: "Not signed in" });

    const token = await adminToken();
    if (!token) return send(503, { error: "not_configured" });

    const gql = `{ shop { currencyCode } shopifyqlQuery(query: "FROM sales SHOW total_sales, net_sales, orders TIMESERIES month SINCE -12m UNTIL today") { tableData { columns { name } rows } } }`;
    const r = await fetch(`https://${SHOP}/admin/api/${API_VERSION}/graphql.json`, {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-Shopify-Access-Token": token },
      body: JSON.stringify({ query: gql })
    });
    const j = await r.json();
    if (!r.ok || j.errors) {
      const msg = (j.errors && j.errors[0] && j.errors[0].message) || "Shopify " + r.status;
      return send(502, { error: msg });
    }
    const table = j.data && j.data.shopifyqlQuery && j.data.shopifyqlQuery.tableData;
    if (!table) return send(502, { error: "Shopify returned no sales table (check the read_reports permission)" });

    let rows = table.rows;
    if (typeof rows === "string") rows = JSON.parse(rows);
    const names = (table.columns || []).map(c => c.name);
    const months = (Array.isArray(rows) ? rows : []).map(row => {
      const o = Array.isArray(row) ? Object.fromEntries(names.map((n, i) => [n, row[i]])) : row;
      return {
        month: String(o.month).slice(0, 7),
        total_sales: Number(o.total_sales) || 0,
        net_sales: Number(o.net_sales) || 0,
        orders: Number(o.orders) || 0
      };
    });
    res.setHeader("Cache-Control", "private, max-age=300");
    return send(200, { currency: (j.data.shop && j.data.shop.currencyCode) || "DKK", months });
  } catch (e) {
    return send(500, { error: String((e && e.message) || e) });
  }
};
