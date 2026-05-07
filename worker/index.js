/**
 * Tesla Auth Proxy + Display - Cloudflare Worker
 * 1. /token  - OAuth 토큰 교환
 * 2. /api/*  - Fleet API 프록시
 * 3. /display - 테슬라 화면용 런처 (T맵 바로 실행)
 */

const CLIENT_ID = '0c603db8-e784-4ff4-9170-f07d4f1e2d55';
const CLIENT_SECRET = 'ta-secret.r2k7Ntla@h*FLIn!';
const REDIRECT_URI = 'https://hadongil19822-blip.github.io/tesla/auth.html';
const TESLA_AUTH_URL = 'https://auth.tesla.com/oauth2/v3/token';
const TESLA_API_BASE = 'https://fleet-api.prd.na.vn.cloud.tesla.com';

function cors() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  };
}

export default {
  async fetch(request) {
    const url = new URL(request.url);
    const origin = request.headers.get('Origin') || '';

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: cors() });
    }

    try {
      // 테슬라 화면용 런처 페이지
      if (url.pathname === '/display') {
        return new Response(DISPLAY_HTML, {
          status: 200,
          headers: { 'Content-Type': 'text/html; charset=utf-8' },
        });
      }

      // 토큰 교환
      if (url.pathname === '/token' && request.method === 'POST') {
        const body = await request.json();
        if (!body.code) return json({ error: 'code required' }, 400);

        const params = new URLSearchParams({
          grant_type: 'authorization_code',
          client_id: CLIENT_ID,
          client_secret: CLIENT_SECRET,
          code: body.code,
          redirect_uri: REDIRECT_URI,
          audience: TESLA_API_BASE,
        });

        const res = await fetch(TESLA_AUTH_URL, {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: params.toString(),
        });

        const data = await res.json();
        return json(data, res.status);
      }

      // Fleet API 프록시
      if (url.pathname.startsWith('/api/')) {
        const headers = new Headers();
        headers.set('Content-Type', 'application/json');
        headers.set('User-Agent', 'TeslaSmartCarWeb/1.0');
        const auth = request.headers.get('Authorization');
        if (auth) headers.set('Authorization', auth);

        let body = null;
        if (request.method === 'POST') body = await request.text();

        const res = await fetch(`${TESLA_API_BASE}${url.pathname}`, {
          method: request.method,
          headers,
          body,
        });

        const data = await res.text();
        return new Response(data, {
          status: res.status,
          headers: { 'Content-Type': 'application/json', ...cors() },
        });
      }

      if (url.pathname === '/') {
        return json({ status: 'ok', service: 'tesla-proxy' }, 200);
      }

      return json({ error: 'Not Found' }, 404);
    } catch (err) {
      return json({ error: err.message }, 500);
    }
  },
};

function json(data, status) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json', ...cors() },
  });
}

// ===== 테슬라 화면용 HTML =====
const DISPLAY_HTML = `<!DOCTYPE html>
<html lang="ko"><head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Tesla Navigator</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{
  background:linear-gradient(135deg,#0a0a1a,#1a1a2e);
  color:#fff;font-family:-apple-system,BlinkMacSystemFont,sans-serif;
  height:100vh;display:flex;flex-direction:column;align-items:center;justify-content:center;
  gap:30px;
}
h1{font-size:36px;font-weight:300;letter-spacing:2px}
.apps{display:flex;gap:24px;flex-wrap:wrap;justify-content:center;max-width:800px}
.app{
  width:200px;height:180px;border-radius:24px;
  display:flex;flex-direction:column;align-items:center;justify-content:center;gap:12px;
  text-decoration:none;color:#fff;font-size:20px;font-weight:bold;
  transition:transform .2s,box-shadow .2s;cursor:pointer;
}
.app:hover{transform:scale(1.05)}
.app .icon{font-size:56px}
.app-tmap{background:linear-gradient(135deg,#2196F3,#0D47A1);box-shadow:0 8px 32px rgba(33,150,243,.4)}
.app-kakao{background:linear-gradient(135deg,#FEE500,#C5A600);color:#333;box-shadow:0 8px 32px rgba(254,229,0,.3)}
.app-naver{background:linear-gradient(135deg,#1EC800,#0D8A00);box-shadow:0 8px 32px rgba(30,200,0,.3)}
.app-youtube{background:linear-gradient(135deg,#FF0000,#B71C1C);box-shadow:0 8px 32px rgba(255,0,0,.3)}
.app-netflix{background:linear-gradient(135deg,#E50914,#831010);box-shadow:0 8px 32px rgba(229,9,20,.3)}
.app-spotify{background:linear-gradient(135deg,#1DB954,#148A3C);box-shadow:0 8px 32px rgba(29,185,84,.3)}
.subtitle{color:#666;font-size:14px;margin-top:10px}
</style></head><body>
<h1>🚗 Tesla Navigator</h1>
<div class="apps">
  <a class="app app-tmap" href="https://tmap.life" target="_self">
    <div class="icon">🗺️</div>T맵
  </a>
  <a class="app app-kakao" href="https://map.kakao.com" target="_self">
    <div class="icon">🚕</div>카카오내비
  </a>
  <a class="app app-naver" href="https://map.naver.com" target="_self">
    <div class="icon">🗾</div>네이버지도
  </a>
  <a class="app app-youtube" href="https://m.youtube.com" target="_self">
    <div class="icon">▶️</div>YouTube
  </a>
  <a class="app app-netflix" href="https://www.netflix.com" target="_self">
    <div class="icon">🎬</div>Netflix
  </a>
  <a class="app app-spotify" href="https://open.spotify.com" target="_self">
    <div class="icon">🎵</div>Spotify
  </a>
</div>
<p class="subtitle">테슬라 브라우저에서 직접 실행됩니다</p>
</body></html>`;
