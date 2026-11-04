// CLEANED COPY - REVIEW BEFORE PUBLISH
// Source (private, NOT published): homelabtwisterlab/homelab-twisterlab/azure/functions/src/storage.js
// Redactions: real IPs, internal domains, emails and secret assignments replaced with placeholders. Manual review required before any publication.

// Stockage en memoire du dernier etat pousse par health-push.ps1.
// En consumption plan, cela ne persiste pas entre instances, mais suffit pour la demo
// (une seule instance, appels frequents). Pour la production, remplacer par Azure Table Storage.
let lastState = null;

function set(state) { lastState = state; }
function get() { return lastState; }

module.exports = { set, get };
