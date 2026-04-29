# Deako Dashboards — Project Context

This repo holds two of three production dashboards for Deako's account development team. They're statically deployed via GitHub Pages and used daily by Brian, Amber, Justin, and DRH leadership.

## The three dashboards

| Name (current) | Public URL | Lives in |
|---|---|---|
| **Executive Dashboard** | https://snappahands.github.io/deako-executive-dashboard/dashboard.html | `dashboard.html` (this repo, root) |
| **Initiatives Dashboard** *(formerly "Brian's Dashboard")* | https://snappahands.github.io/deako-executive-dashboard/BrianDashboard/ | `BrianDashboard/index.html` (this repo) |
| **Accounts Dashboard** *(formerly "Amber's" / "Builder Dashboard")* | https://snappahands.github.io/amber-dashboard/ | `AmberDashboard/` — **a nested separate git repo**, remote `github.com/snappahands/amber-dashboard.git` |

The user may refer to any of these by their old names. Treat "Brian's" = Initiatives, "Amber's"/"Builder" = Accounts.

A shared top-of-page nav bar cross-links all three (teal=Executive, gold=Initiatives, purple=Accounts).

### AmberDashboard nested-repo trap

`AmberDashboard/` is its own git repo nested inside this one. **Do not** `git add AmberDashboard/` from the parent — it commits as a gitlink/submodule and breaks GitHub Pages serving the actual files. Always commit Amber edits from inside its own repo:

```bash
git -C AmberDashboard add ...
git -C AmberDashboard commit ...
git -C AmberDashboard push origin master
```

Both repos use HTTPS remotes and require `snappahands@` embedded in the URL (`https://snappahands@github.com/...`). Without it, `git-credential-manager.exe` opens an interactive auth prompt the harness can't fulfill and the push hangs forever. If multiple `git-credential-manager.exe` / `git-remote-https.exe` processes are alive, `taskkill //F //IM git-credential-manager.exe; taskkill //F //IM git-remote-https.exe` clears the deadlock without losing the local commit.

## Working rules

- **Autodeploy after every edit.** Commit and push immediately on any dashboard change. The user expects to see updates the moment colleagues refresh — don't batch and don't wait to be asked.
- **Version-bump every change.** Each dashboard has a version badge in its top right (`#version-badge` for Initiatives/Accounts, inline span in Executive's header). Increment it with every commit so the user can verify the right version is live.
- **Recent versions:** Executive `v5.x`, Initiatives `v12.x`–`v13.x`, Accounts `v4.x`. Use the next decimal.
- **Don't ask permission to retry a failing push.** Diagnose, fix (kill credential-manager hang, fix remote URL), retry. Only stop if the user has to do something themselves.

## Data sources

The dashboards are static-data-driven (no backend). Each major data series has a canonical CSV that regenerates a `.js` file. When data is "stale", refresh from the latest export.

| Data | JS file | Source CSV |
|---|---|---|
| Conversion rates by division | `BrianDashboard/conv_data.js` | `converison_by_division_*.csv` (HEX export) |
| Closes by division | `BrianDashboard/closes_data.js` | from HEX |
| Ratifications | `BrianDashboard/ratif_data.js` | from HEX |
| HST Direct (per-division monthly) | `BrianDashboard/ss1_data.js` | `HST Direct Sales_*.csv` (Shopify export) |
| HST Top 10 analysis | `BrianDashboard/hst_top10.js` | derived from same Shopify export |
| Rainmaker pack tiers (p25/p10/p8/total) | `BrianDashboard/rainmakers.js` (`p25/p10/p8/t`) | **`Rainmakers QBR_*.csv`** — source of truth |
| Rainmaker contact + h3/l3 | `BrianDashboard/rainmakers.js` (`em/ph/cm/h3/l3`) | `Rainmakers_*.csv` (per-agent-per-community detail) |
| Staying/undecided divisions + projected starts | `BrianDashboard/staying_divisions.js` | Holly's "DRH DIVISIONS_1_12_26 - Model Home Prioritization" sheet — column E STAYING/UNDECIDED only |
| Monthly Bookings/Revenue (Executive) | `dashboard.html` `DEFAULTS.monthly` | row 58 ("Actuals") of `Justin_Netsuite_Active Builder Upgrades - JUSTIN BOOKINGS Table (N).csv` |
| ITM Before/After per visit | `BrianDashboard/index.html` `VISITS` array | hand-maintained training log |

When refreshing data: **bump `dataVersion`** in `DEFAULTS` (Executive only) so existing visitors' localStorage cache busts.

## Live shared state — JSONBin

Two dashboards use JSONBin as a shared backing store so edits propagate to all viewers (no backend, no auth required for visitors).

| Bin | ID | Used by | Stores |
|---|---|---|---|
| Accounts builders | `69cd569e36566621a86da1bb` | `AmberDashboard/index.html` | the `BUILDERS` array — every card, all field edits autosave |
| Initiatives outreach | `69f24b0e36566621a807df56` | `BrianDashboard/index.html` | `{ agents: { 'name|division': {c, e, t, notes, updated, events} } }` — call/email/text checkboxes + notes |

Master key is embedded in the client (already public — these are public read+write bins by design). Both use a **stale-while-revalidate** pattern: render immediately from a localStorage cache, fetch JSONBin async, re-render only if the response differs. Saves debounce-push.

**JSONBin Cloudflare quirk** (only matters for Python scripts): default `urllib` User-Agent is blocked with HTTP 403 / Cloudflare error 1010. Always set `User-Agent: Mozilla/5.0 (...) Chrome/120.0.0.0 ...` on script requests. Browser fetches work fine.

## Builder filter (Initiatives)

Initiatives has a header dropdown that scopes the whole view to a specific medium builder (default: DR Horton). Implemented by snapshotting all data globals at startup into `_DRH_SNAPSHOT` (lazily — only when first switching away from DRH) and mutating each global to a shape-preserving empty version when a non-DRH builder is selected. Selection persists in `localStorage` (`initiatives_builder`). Per-builder data files don't exist yet — those are filled in as builders bring their data.

## Repo conventions

- Commit messages: `<Dashboard> v<old>→<new>: <one-line summary>` for dashboard edits. Body explains the *why*. Co-author trailer: `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>`.
- Don't create planning/decision/analysis Markdown files unless asked.
- Helper scripts (`_*.py`) used during a task should be deleted after use, not committed.
