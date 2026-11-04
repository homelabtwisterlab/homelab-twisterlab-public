// CLEANED COPY - REVIEW BEFORE PUBLISH
// Source (private, NOT published): homelabtwisterlab/homelab-twisterlab/cloudflare/workers/twisterlab/src/index.js
// Redactions: real IPs, internal domains, emails and secret assignments replaced with placeholders. Manual review required before any publication.

// TwisterLab — Cloudflare Worker (HTTP trigger)
//
// Substitut gratuit de la Function App Azure :
//   Azure Functions -> nécessite une souscription (carte bancaire)
//   Cloudflare Workers -> 100 000 requêtes/jour, SANS carte, gratuit a vie
//
// Test :
//   curl "https://<worker>.<sous-domaine>.workers.dev/?name=core"
//   curl "https://<worker>.<sous-domaine>.workers.dev/health"

const LAB = {
  name: 'TwisterLab',
  nodes: 3,
  orchestrator: 'hermes',
  verification: 'sha256',
};

export default {
  async fetch(request) {
    const url = new URL(request.url);
    const name = url.searchParams.get('name') || 'twisterlab';

    if (url.pathname === '/health') {
      return json({ status: 'ok', ...LAB });
    }

    return json({
      ...LAB,
      message: `hello, ${name}`,
      node: 'core',
    });
  },
};

function json(obj) {
  return new Response(JSON.stringify(obj, null, 2) + '\n', {
    headers: { 'content-type': 'application/json; charset=utf-8' },
  });
}
