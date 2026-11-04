// CLEANED COPY - REVIEW BEFORE PUBLISH
// Source (private, NOT published): homelabtwisterlab/homelab-twisterlab/azure/functions/src/functions/ingesthomelabstatus.js
// Redactions: real IPs, internal domains, emails and secret assignments replaced with placeholders. Manual review required before any publication.

const { app } = require("@azure/functions");
const storage = require("../storage");

const INGEST_KEY = process.env.INGEST_KEY || "";

app.http("IngestHomelabStatus", {
  methods: ["POST"],
  authLevel: "anonymous",
  route: "ingesthomelabstatus",
  handler: async (request, context) => {
    const provided = request.headers.get("x-ingest-key") || "";
    if (!INGEST_KEY || provided !== INGEST_KEY) {
      return { status: 401, body: "Unauthorized" };
    }
    let body;
    try { body = await request.json(); } catch { body = null; }
    if (!body || !Array.isArray(body.nodes)) {
      return { status: 400, body: "Bad request" };
    }
    storage.set({ measured_at: body.measured_at || new Date().toISOString(), source: body.source || "unknown", nodes: body.nodes, received_at: new Date().toISOString() });
    return { status: 200, jsonBody: { ok: true } };
  },
});
