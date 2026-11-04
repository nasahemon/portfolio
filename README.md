# Portfolio: Hasibul Hasan Emon

Personal site: a static HTML/CSS/JS site on **Vercel**, shipped by a **GitHub Actions** pipeline.
Small site, production-style delivery.

## Pipeline

```
Pull request ──► checks ──► build once ──► preview deploy ──► smoke test ──► URL commented on PR
                (format, HTML, shellcheck, internal links)

Push to main ──► checks ──► build once (prod) ──► deploy with --skip-domain (not live)
                                                 ──► smoke test ──► vercel promote (live) ──► verify prod
```

- **Build once, deploy the prebuilt output:** `vercel build` then `vercel deploy --prebuilt`. What gets tested is what goes live.
- **Staged production release:** the production build is deployed without the domain, smoke-tested, then promoted.
  Rollback = `vercel rollback` or promote the previous deployment.
- **One path to production:** Vercel's own Git auto-deploys are disabled (`vercel.json` → `git.deploymentEnabled: false`).
- **Security headers:** strict CSP (no inline scripts or styles, no third-party origins), HSTS, nosniff, Referrer-Policy,
  Permissions-Policy, frame-ancestors none. The smoke test fails if they go missing.
- **Supply chain:** tool versions pinned in `package-lock.json`, Dependabot for npm + GitHub Actions, least-privilege
  workflow `permissions`.
- **Optional manual gate:** add required reviewers to the `production` environment in GitHub settings.

## Layout

```
site/                 # the published site (index.html, styles.css, main.js, assets/)
scripts/smoke-test.sh # post-deploy checks (status, content, assets, headers, 404)
vercel.json           # output dir, headers, disables Vercel Git deploys
.github/workflows/    # pipeline.yml
```

## Local development

```bash
npm ci
npm run serve        # http://localhost:4321
npm run check        # formatting + HTML validation
npm run format       # auto-format
```

## One-time setup

1. **GitHub:** create a public repo `nasahemon/portfolio` and push `main`.
2. **Vercel:** create a project (no Git connection needed), then link it locally:
   `npx vercel login` → `npx vercel link` → copy `orgId` and `projectId` from `.vercel/project.json`.
3. **Vercel token:** Vercel → Account Settings → Tokens → create a token scoped to this project's team.
4. **GitHub secrets** (repo → Settings → Secrets and variables → Actions):
   - `VERCEL_TOKEN`
   - `VERCEL_ORG_ID`
   - `VERCEL_PROJECT_ID`
   - `VERCEL_AUTOMATION_BYPASS_SECRET` (needed only if Deployment Protection is on: Vercel → Project → Settings →
     Deployment Protection → Protection Bypass for Automation)
5. **Branch protection on `main`:** require pull requests and the `Checks` status before merging.
6. **Domain:** the default is `hasanemon.vercel.app` (set in Vercel → Domains). If you change it, update the URLs in
   `site/index.html`, `site/robots.txt`, `site/sitemap.xml` and `.github/workflows/pipeline.yml`.

## Still to provide

- `site/assets/photo.jpg` (replace the black placeholder in the hero)
- `site/assets/cv.pdf` (then remove the line in `.lycheeignore`)
- `site/assets/og-image.png` (1200×630 social preview; currently a black placeholder)
