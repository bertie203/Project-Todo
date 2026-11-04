import { AuthorizationError, CimdFetchError, OAuthProvider, type OAuthHelpers } from '@cloudflare/workers-oauth-provider';

import { Store } from './db';
import { handleMcp } from './mcp';

export interface Env {
  DB: D1Database;
  OAUTH_KV: KVNamespace;
  TIME_ZONE: string;
  /** Password for signing Claude in. Secret. */
  LOGIN_PASSWORD: string;
  /** Token the phone app uses for /api/sync. Secret. */
  APP_TOKEN: string;
  /** Only set in .dev.vars for local testing. Enables /dev/mcp. */
  DEV_MCP_TOKEN?: string;
  OAUTH_PROVIDER: OAuthHelpers;
}

const escape = (v: string) => v.replace(/[&<>"']/g, (c) => `&#${c.charCodeAt(0)};`);

/** Compares secrets without leaking timing. */
async function sameSecret(a: string, b: string): Promise<boolean> {
  if (!b) return false;
  const enc = new TextEncoder();
  const [ha, hb] = await Promise.all([
    crypto.subtle.digest('SHA-256', enc.encode(a)),
    crypto.subtle.digest('SHA-256', enc.encode(b)),
  ]);
  return crypto.subtle.timingSafeEqual(ha, hb);
}

function bearer(request: Request): string {
  const h = request.headers.get('Authorization') ?? '';
  return h.startsWith('Bearer ') ? h.slice(7) : '';
}

function page(body: string, status = 200, headers = new Headers()): Response {
  headers.set('Content-Type', 'text/html; charset=utf-8');
  return new Response(
    `<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Project Todo</title>
<style>body{font-family:system-ui,sans-serif;max-width:28rem;margin:3rem auto;padding:0 1rem;line-height:1.5}
input{font-size:1rem;padding:.5rem;width:100%;box-sizing:border-box}button{font-size:1rem;padding:.5rem 1rem;margin-right:.5rem}
.err{color:#b00}</style></head><body>${body}</body></html>`,
    { status, headers },
  );
}

function consentForm(clientName: string, redirectHost: string, loopback: boolean, handle: string, err = ''): string {
  return `<h1>Project Todo</h1>
<p><strong>${escape(clientName)}</strong> wants to read and change your tasks.
Access will be sent to <strong>${escape(redirectHost)}</strong>.</p>
${loopback ? '<p><strong>This sends access to an app on this computer.</strong> Continue only if you started signing in from it.</p>' : ''}
${err ? `<p class="err">${escape(err)}</p>` : ''}
<form method="post">
<input type="hidden" name="handle" value="${escape(handle)}">
<p><label>Password<br><input type="password" name="password" autocomplete="current-password" autofocus></label></p>
<p><button name="decision" value="approve">Allow</button><button name="decision" value="deny">Deny</button></p>
</form>`;
}

async function authorize(request: Request, env: Env): Promise<Response> {
  const oauth = env.OAUTH_PROVIDER;
  try {
    if (request.method === 'GET') {
      const req = await oauth.parseAuthRequest(request);
      const d = await oauth.describeConsent(req);
      const consent = await oauth.beginConsent(req);
      return page(consentForm(d.clientName, d.redirectHost, d.redirectIsLoopback, consent.handle), 200, consent.headers);
    }
    const form = await request.formData();
    const handle = String(form.get('handle') ?? '');
    if (form.get('decision') !== 'approve') {
      const denied = await oauth.denyConsent(request, handle);
      return new Response(null, { status: 302, headers: denied.headers });
    }
    if (!(await sameSecret(String(form.get('password') ?? ''), env.LOGIN_PASSWORD))) {
      // Wrong password: start again so a fresh handle is issued.
      return page('<h1>Project Todo</h1><p class="err">Wrong password.</p><p>Go back to Claude and try connecting again.</p>', 401);
    }
    const approved = await oauth.approveConsent(request, handle, { scope: ['tasks'] });
    const { redirectTo } = await oauth.completeAuthorization({
      request: approved.request,
      userId: 'owner',
      metadata: {},
      scope: ['tasks'],
      props: { userId: 'owner' },
    });
    approved.headers.set('Location', redirectTo);
    return new Response(null, { status: 302, headers: approved.headers });
  } catch (e) {
    if (e instanceof AuthorizationError && e.redirectTo) return Response.redirect(e.redirectTo, 302);
    if (e instanceof AuthorizationError || e instanceof CimdFetchError) {
      const msg = e instanceof AuthorizationError ? e.description : 'This app could not be verified.';
      return page(`<h1>Project Todo</h1><p class="err">${escape(msg ?? 'Sign-in failed.')}</p>`, 400);
    }
    throw e;
  }
}

const toolContext = (env: Env) => ({ store: new Store(env.DB), timeZone: env.TIME_ZONE || 'Europe/London' });

/** Everything that is not the OAuth-protected /mcp route. */
const defaultHandler: ExportedHandler<Env> = {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname === '/authorize') return authorize(request, env);

    // Phone app: swap the password for the sync token once.
    if (url.pathname === '/api/login' && request.method === 'POST') {
      const body = (await request.json().catch(() => ({}))) as { password?: string };
      if (!(await sameSecret(body.password ?? '', env.LOGIN_PASSWORD))) {
        return Response.json({ error: 'Wrong password' }, { status: 401 });
      }
      return Response.json({ token: env.APP_TOKEN });
    }

    // Phone app: two-way sync.
    if (url.pathname === '/api/sync' && request.method === 'POST') {
      if (!(await sameSecret(bearer(request), env.APP_TOKEN))) {
        return Response.json({ error: 'Not signed in' }, { status: 401 });
      }
      const body = (await request.json().catch(() => null)) as { since?: number; projects?: any[]; tasks?: any[] } | null;
      if (!body) return Response.json({ error: 'Bad request' }, { status: 400 });
      try {
        const out = await new Store(env.DB).sync(Number(body.since ?? 0), body);
        return Response.json(out);
      } catch (e) {
        return Response.json({ error: e instanceof Error ? e.message : 'Sync failed' }, { status: 400 });
      }
    }

    // Local testing only.
    if (url.pathname === '/dev/mcp' && env.DEV_MCP_TOKEN && (await sameSecret(bearer(request), env.DEV_MCP_TOKEN))) {
      return handleMcp(request, toolContext(env));
    }

    if (url.pathname === '/') {
      return page('<h1>Project Todo</h1><p>Add <code>' + escape(url.origin) + '/mcp</code> as a custom connector in Claude.</p>');
    }
    return new Response('Not found', { status: 404 });
  },
};

const apiHandler = {
  async fetch(request: Request, env: Env) {
    return handleMcp(request, toolContext(env));
  },
};

// The resource URL must be absolute, so the provider is built per origin.
const providers = new Map<string, OAuthProvider<Env>>();

function providerFor(origin: string): OAuthProvider<Env> {
  let p = providers.get(origin);
  if (!p) {
    p = new OAuthProvider<Env>({
      apiRoute: '/mcp',
      apiHandler,
      defaultHandler,
      authorizeEndpoint: '/authorize',
      tokenEndpoint: '/oauth/token',
      clientRegistrationEndpoint: '/oauth/register',
      clientIdMetadataDocumentEnabled: true,
      scopesSupported: ['tasks'],
      resourceMetadata: { resource: `${origin}/mcp`, authorization_servers: [origin] },
    });
    providers.set(origin, p);
  }
  return p;
}

export default {
  fetch(request, env, ctx) {
    return providerFor(new URL(request.url).origin).fetch(request, env, ctx);
  },
} satisfies ExportedHandler<Env>;
