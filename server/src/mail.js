// Sending email: through Resend when RESEND_API_KEY is set; with DEV_MAIL=1 (local only)
// into the outbox table instead, so the verify and reset flows work end to end locally.
import { now } from './util.js';

export async function sendMail(env, to, subject, text) {
  if (env.RESEND_API_KEY) {
    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { Authorization: `Bearer ${env.RESEND_API_KEY}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ from: env.MAIL_FROM, to, subject, text }),
    });
    if (!res.ok) console.error('email not sent', res.status, await res.text());
    return;
  }
  if (env.DEV_MAIL === '1') {
    await env.DB.prepare('INSERT INTO outbox (to_addr, subject, body, created_at) VALUES (?, ?, ?, ?)').bind(to, subject, text, now()).run();
    console.log(`[mail to ${to}] ${subject}\n${text}`);
    return;
  }
  console.warn(`No email sender is set up; "${subject}" to ${to} was not sent.`);
}

export const verifyEmail = (link) => `Welcome to Deck of Fools!

Tap this link to confirm your email address:
${link}

If you didn't create an account, you can ignore this email.`;

export const resetEmail = (link) => `Someone asked to reset your Deck of Fools password.

Tap this link to choose a new one (it works for one hour):
${link}

If it wasn't you, you can ignore this email: your password hasn't changed.`;
