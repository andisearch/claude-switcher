# airun.me Website

Static landing page for [airun.me](https://airun.me), deployed via GitHub Pages.

## Files

- `index.html` — Single-page landing site (inline CSS/JS, no build step)
- `CNAME` — Custom domain configuration
- `.nojekyll` — Disables Jekyll processing
- `PROVIDERS.md` — Provider documentation (linked from repo README)

## GitHub Pages Deployment

1. **Repo Settings → Pages**:
   - Source: "Deploy from a branch"
   - Branch: `main`, folder: `/docs`
   - Save

2. **DNS Configuration** (at your domain registrar):
   - A records (apex domain):
     - `185.199.108.153`
     - `185.199.109.153`
     - `185.199.110.153`
     - `185.199.111.153`
   - CNAME record: `www` → `andisearch.github.io`

3. **Back in Repo Settings → Pages**:
   - Custom domain: `airun.me`
   - Check "Enforce HTTPS" (available after DNS propagates, up to 24h)

## Verify

- `andisearch.github.io/airun` should work immediately after enabling Pages
- `airun.me` works after DNS propagation + HTTPS provisioning

## Fallback: AWS Amplify

If GitHub Pages doesn't work (e.g., org-level Pages conflicts):
- Create an Amplify app pointing to the `docs/` folder
- Configure custom domain in Amplify console
- Amplify handles SSL automatically

## Editing

Single HTML file, no build. Edit `index.html` directly and push to `main`.

## Analytics

GitHub Pages analytics (website only): PostHog analytics script included in HTML for airun.me web traffic only. No tracking or analytics is used in airun itself.
