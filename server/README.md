# Deck of Fools API

Cloudflare Worker + D1: accounts, cloud saves, the daily run, leaderboards and profile stats.
Plain JavaScript (no build step), in `src/`.

## Run it locally

```
npm install
npm run dev        # http://localhost:8787, local D1 in .wrangler/ (migrations applied first)
npm test           # 17 end-to-end tests against a throwaway local copy
```

The game's web build (http://localhost:3790) talks to http://localhost:8787 by default
(Godot project setting `deck_of_fools/api_url`). With the API up, `tools\test.ps1` in the game
also runs `tests/online_smoke.tscn`: the game's own Online code against this server.

Locally, emails aren't sent: they go to an outbox (`.dev.vars` sets `DEV_MAIL=1`). See them at
http://localhost:8787/v1/dev/outbox; the confirm and reset links in them work.

## What it does

| Area | Endpoints |
|---|---|
| Accounts | `POST /v1/auth/guest`, `/signup`, `/login`, `/logout`, `/apple`, `/google`, `/forgot`, `/reset`, `/resend-verification`; pages `GET /verify`, `GET /reset` |
| Player | `GET/PATCH/DELETE /v1/me`, `GET /v1/me/stats` |
| Cloud save | `GET /v1/save`, `PUT /v1/save` (409 with the cloud copy when the device is behind) |
| Daily run | `GET /v1/daily`, `POST /v1/daily/start` (one ranked attempt per UTC day) |
| Runs | `POST /v1/runs` (checked for plausibility, rate-limited, action log kept) |
| Leaderboards | `GET /v1/leaderboards/daily?date=`, `/best_hand`, `/town?stake=` |

- Passwords: PBKDF2-SHA256, 100,000 iterations (the Workers maximum). Sessions are random
  bearer tokens stored only as SHA-256 hashes.
- Apple/Google: identity tokens are checked against the providers' published keys, issuer,
  audience (`APPLE_CLIENT_IDS`, `GOOGLE_CLIENT_IDS`) and expiry.
- Runs can't be replayed on the server (the rules live in the game), so a run is checked for
  plausibility against its action log and kept for later checks. Treat the boards as honest
  play until a server-side replay exists.

## Before it goes live (needs Luca's go-ahead)

1. `npx wrangler d1 create deck-of-fools`, then put the id in `wrangler.toml`.
2. `npx wrangler d1 migrations apply deck-of-fools --remote`.
3. In `wrangler.toml` `[vars]`: `PUBLIC_URL` (the API's address), `MAIL_FROM`,
   `APPLE_CLIENT_IDS` (the iOS bundle id / Services ID), `GOOGLE_CLIENT_IDS` (OAuth client ids).
4. Secret: `npx wrangler secret put RESEND_API_KEY` (or swap `src/mail.js` for another sender).
5. The Workers Paid plan ($5/month) may be needed: PBKDF2 uses more CPU than the free plan allows.
6. `npx wrangler deploy`, then set the game's `deck_of_fools/api_url` to the live address.
