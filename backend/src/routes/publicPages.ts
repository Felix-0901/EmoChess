import { Router } from 'express';

const router = Router();

const updatedAt = '2026-05-13';
const supportEmail = 'beioverworked@gmail.com';

const baseStyles = `
  :root {
    color-scheme: light;
    --bg: #f7faf9;
    --surface: #ffffff;
    --text: #18312f;
    --muted: #5f706e;
    --line: #dce7e4;
    --accent: #0f766e;
  }
  * { box-sizing: border-box; }
  body {
    margin: 0;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    background: var(--bg);
    color: var(--text);
    line-height: 1.7;
  }
  main {
    width: min(920px, calc(100% - 32px));
    margin: 0 auto;
    padding: 48px 0 64px;
  }
  article {
    background: var(--surface);
    border: 1px solid var(--line);
    border-radius: 8px;
    padding: clamp(24px, 4vw, 48px);
  }
  h1 {
    margin: 0 0 8px;
    font-size: clamp(30px, 5vw, 44px);
    line-height: 1.15;
    letter-spacing: 0;
  }
  h2 {
    margin: 32px 0 10px;
    font-size: 22px;
    line-height: 1.3;
    letter-spacing: 0;
  }
  p, li { font-size: 16px; }
  p { margin: 10px 0; }
  ul { padding-left: 1.4rem; margin: 10px 0; }
  a { color: var(--accent); text-decoration-thickness: 1px; text-underline-offset: 3px; }
  .meta { color: var(--muted); margin-bottom: 28px; }
  .notice {
    border-left: 4px solid var(--accent);
    background: #eef8f6;
    padding: 14px 16px;
    margin: 24px 0;
  }
  footer {
    margin-top: 28px;
    color: var(--muted);
    font-size: 14px;
  }
`;

const page = (title: string, body: string) => `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${title} | EmoChess</title>
  <style>${baseStyles}</style>
</head>
<body>
  <main>
    <article>
      ${body}
      <footer>
        <p>EmoChess by Beioverworked</p>
      </footer>
    </article>
  </main>
</body>
</html>`;

router.get('/privacy', (_req, res) => {
    res.type('html').send(
        page(
            'Privacy Policy',
            `
      <h1>EmoChess Privacy Policy</h1>
      <p class="meta">Last updated: ${updatedAt}</p>

      <p>EmoChess is a chess-based learning and self-reflection app that combines gameplay, emotional check-ins, and post-game review. This Privacy Policy explains how we collect, use, store, and protect information when you use EmoChess.</p>

      <div class="notice">
        <p>EmoChess is not a medical, diagnostic, or therapy service. Emotional records and AI-assisted content in the app are provided for learning, supportive reflection, and personal review only.</p>
      </div>

      <h2>Information We May Collect</h2>
      <ul>
        <li>Account information: email address, display name, login status, and required authentication information.</li>
        <li>Game information: chess moves, game results, game duration, saved game records, and related statistics.</li>
        <li>Emotion information: emotional check-ins, emotion events, and reflection data that users choose to provide in the app.</li>
        <li>AI interaction information: supportive chat messages, game analysis requests, and AI-assisted report results generated through the app.</li>
        <li>Technical information: server logs, error logs, request timestamps, and basic connection information needed to maintain service stability and security.</li>
      </ul>

      <h2>How We Use Information</h2>
      <ul>
        <li>To provide account login, data synchronization, and cross-device access.</li>
        <li>To save and display game history, emotion trends, titles, and personal statistics.</li>
        <li>To generate supportive prompts, game analysis, and AI-assisted reports within the app.</li>
        <li>To maintain system security, detect abnormal activity, debug issues, and improve service stability.</li>
        <li>To respond to user support requests and handle data-related requests.</li>
      </ul>

      <h2>Third-Party Services</h2>
      <p>EmoChess may use cloud hosting, database, deployment, and AI API providers to operate the service. These providers process information only as needed to provide app functionality, maintain the system, and support security operations.</p>

      <h2>Data Retention and Security</h2>
      <p>We use reasonable technical and organizational measures to protect information. Passwords are not stored in plain text. Information is retained for as long as needed to provide the service, comply with legal requirements, resolve disputes, and maintain security.</p>

      <h2>Advertising and Tracking</h2>
      <p>EmoChess does not currently collect information for third-party advertising tracking, and we do not sell users' personal information.</p>

      <h2>Children and Guardians</h2>
      <p>If a child uses EmoChess, a parent or legal guardian should understand and consent to the way information is handled. Parents or guardians may contact us to request access to or deletion of account-related information.</p>

      <h2>Your Choices and Rights</h2>
      <p>You may contact us to request access, correction, or deletion of your account and related information. Some deletions may affect synchronization, analysis, and history features in the app.</p>

      <h2>Contact Us</h2>
      <p>If you have questions about this Privacy Policy or how information is handled, contact us at <a href="mailto:${supportEmail}">${supportEmail}</a>.</p>

      <h2>Changes to This Policy</h2>
      <p>We may update this Privacy Policy as our features, legal requirements, or services change. The latest update date will be shown on this page.</p>
      `
        )
    );
});

router.get('/support', (_req, res) => {
    res.type('html').send(
        page(
            'Support',
            `
      <h1>EmoChess Support</h1>
      <p class="meta">Last updated: ${updatedAt}</p>

      <p>If you need help with EmoChess, please contact us by email:</p>
      <p><a href="mailto:${supportEmail}">${supportEmail}</a></p>

      <h2>What to Include</h2>
      <ul>
        <li>Your device model, such as the iPhone or iPad model.</li>
        <li>Your iOS version.</li>
        <li>Your EmoChess app version.</li>
        <li>The time the issue happened and the steps that led to it.</li>
        <li>A screenshot of the issue, if available.</li>
      </ul>

      <h2>Account and Data Requests</h2>
      <p>If you want to access, correct, or delete your account or related data, please contact us using the email address associated with your account and describe your request. To protect account security, we may need to verify that you are authorized to make the request.</p>

      <h2>Privacy Policy</h2>
      <p>Please read the <a href="/privacy">EmoChess Privacy Policy</a> to learn how information is collected, used, and stored.</p>
      `
        )
    );
});

export default router;
