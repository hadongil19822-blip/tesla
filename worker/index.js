/**
 * Tesla Auth Proxy - Cloudflare Worker
 * 
 * 브라우저(프론트엔드)에서 직접 호출할 수 없는 Tesla API를
 * 서버 사이드에서 대신 중계해주는 프록시 서버입니다.
 * 
 * 역할:
 * 1. /token  - OAuth 인증코드 → Access Token 교환
 * 2. /api/*  - Fleet API 호출 중계 (CORS 우회)
 */

const ALLOWED_ORIGIN = 'https://hadongil19822-blip.github.io';

const CLIENT_ID = '0c603db8-e784-4ff4-9170-f07d4f1e2d55';
const CLIENT_SECRET = 'ta-secret.r2k7Ntla@h*FLIn!';
const REDIRECT_URI = 'https://hadongil19822-blip.github.io/tesla/auth.html';

const TESLA_AUTH_URL = 'https://auth.tesla.com/oauth2/v3/token';
const TESLA_API_BASE = 'https://fleet-api.prd.na.vn.cloud.tesla.com';

function corsHeaders(origin) {
  return {
    'Access-Control-Allow-Origin': origin === ALLOWED_ORIGIN ? ALLOWED_ORIGIN : '',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Max-Age': '86400',
  };
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const origin = request.headers.get('Origin') || '';

    // CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders(origin) });
    }

    // 허용된 출처만 허용
    if (origin && origin !== ALLOWED_ORIGIN) {
      return new Response('Forbidden', { status: 403 });
    }

    try {
      // 1) 토큰 교환 엔드포인트
      if (url.pathname === '/token' && request.method === 'POST') {
        const body = await request.json();
        const code = body.code;
        if (!code) {
          return jsonResponse({ error: 'code is required' }, 400, origin);
        }

        const params = new URLSearchParams({
          grant_type: 'authorization_code',
          client_id: CLIENT_ID,
          client_secret: CLIENT_SECRET,
          code: code,
          redirect_uri: REDIRECT_URI,
          audience: TESLA_API_BASE,
        });

        const tokenRes = await fetch(TESLA_AUTH_URL, {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: params.toString(),
        });

        const tokenData = await tokenRes.json();
        return jsonResponse(tokenData, tokenRes.status, origin);
      }

      // 2) Fleet API 프록시 엔드포인트
      if (url.pathname.startsWith('/api/')) {
        const targetPath = url.pathname; // e.g. /api/1/vehicles
        const targetUrl = `${TESLA_API_BASE}${targetPath}`;

        const headers = new Headers();
        headers.set('Content-Type', 'application/json');
        headers.set('User-Agent', 'TeslaSmartCarWeb/1.0');
        
        const authHeader = request.headers.get('Authorization');
        if (authHeader) {
          headers.set('Authorization', authHeader);
        }

        let reqBody = null;
        if (request.method === 'POST') {
          reqBody = await request.text();
        }

        const apiRes = await fetch(targetUrl, {
          method: request.method,
          headers: headers,
          body: reqBody,
        });

        const apiData = await apiRes.text();
        return new Response(apiData, {
          status: apiRes.status,
          headers: {
            'Content-Type': 'application/json',
            ...corsHeaders(origin),
          },
        });
      }

      // Health check
      if (url.pathname === '/') {
        return jsonResponse({ status: 'ok', service: 'tesla-auth-proxy' }, 200, origin);
      }

      return jsonResponse({ error: 'Not Found' }, 404, origin);
    } catch (err) {
      return jsonResponse({ error: err.message }, 500, origin);
    }
  },
};

function jsonResponse(data, status, origin) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...corsHeaders(origin || ''),
    },
  });
}
