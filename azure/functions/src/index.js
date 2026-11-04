// CLEANED COPY - REVIEW BEFORE PUBLISH
// Source (private, NOT published): homelabtwisterlab/homelab-twisterlab/azure/functions/src/index.js
// Redactions: real IPs, internal domains, emails and secret assignments replaced with placeholders. Manual review required before any publication.

const { app } = require("@azure/functions");
require("./functions/httphello");
require("./functions/ingesthomelabstatus");
require("./functions/gethomelabstatus");
module.exports = app;
