// CLEANED COPY - REVIEW BEFORE PUBLISH
// Source (private, NOT published): homelabtwisterlab/homelab-twisterlab/azure/functions/src/functions/httphello.js
// Redactions: real IPs, internal domains, emails and secret assignments replaced with placeholders. Manual review required before any publication.

const { app } = require("@azure/functions");

app.http("HttpHello", {
  methods: ["GET", "POST"],
  authLevel: "anonymous",
  handler: async (request, context) => {
    const name = request.query.get("name") || (await request.json().catch(() => ({}))).name || "twisterlab";
    return { status: 200, body: `Hello, ${name}!` };
  },
});
