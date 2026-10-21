// The two pages players reach from an email: "your address is confirmed" and "choose a new
// password". Plain, in the game's colours, readable on a phone.

const page = (title, inner) => `<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>${title}</title>
<style>
  body { margin: 0; min-height: 100vh; display: grid; place-items: center; background: #1b1026; color: #f3ead8; font: 16px/1.5 system-ui, sans-serif; padding: 16px; box-sizing: border-box; }
  main { max-width: 380px; width: 100%; background: #2b1a3d; border: 2px solid #3d2756; border-radius: 10px; padding: 24px; }
  h1 { color: #f0b84a; font-size: 22px; margin: 0 0 8px; }
  p { margin: 0 0 16px; color: #d8cce6; }
  label { display: block; font-size: 14px; margin: 12px 0 4px; }
  input { width: 100%; box-sizing: border-box; padding: 10px; border-radius: 6px; border: 1px solid #3d2756; background: #1b1026; color: #f3ead8; font: inherit; }
  button { margin-top: 16px; width: 100%; padding: 12px; border: 0; border-bottom: 3px solid #8a2a1e; border-radius: 6px; background: #e0503c; color: #fff; font: inherit; cursor: pointer; }
  #message { margin-top: 12px; min-height: 1.5em; }
</style></head><body><main>${inner}</main></body></html>`;

const escape = (text) => String(text).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);

export const verifiedPage = (ok) => page('Deck of Fools', ok
  ? '<h1>Email confirmed</h1><p>Thanks! You can go back to the game.</p>'
  : '<h1>That link has expired</h1><p>Ask the game for a new confirmation email from your profile.</p>');

export const resetPage = (token) => page('Deck of Fools: new password', `
  <h1>Choose a new password</h1>
  <p>At least 8 characters.</p>
  <form id="form">
    <label for="password">New password</label>
    <input id="password" type="password" autocomplete="new-password" minlength="8" required>
    <label for="again">Type it again</label>
    <input id="again" type="password" autocomplete="new-password" minlength="8" required>
    <button type="submit">Save the new password</button>
    <div id="message" role="status"></div>
  </form>
  <script>
    const form = document.getElementById('form');
    const message = document.getElementById('message');
    form.addEventListener('submit', async (event) => {
      event.preventDefault();
      const password = document.getElementById('password').value;
      if (password !== document.getElementById('again').value) { message.textContent = "The two passwords don't match."; return; }
      const res = await fetch('/v1/auth/reset', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ token: ${JSON.stringify(escape(token))}, password }) });
      const data = await res.json();
      message.textContent = res.ok ? 'Done. Sign in with your new password in the game.' : data.error;
      if (res.ok) form.querySelector('button').disabled = true;
    });
  </script>`);
