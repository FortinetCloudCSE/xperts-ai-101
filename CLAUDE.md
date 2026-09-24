# CLAUDE.md — xperts-ai-101

> Global preferences: `~/.claude/CLAUDE.md`. Ecosystem: CentralRepo (Hugo image + theme + shared shortcodes), UserRepo (template this was cloned from), faig-training-workshop (Day 2 follow-on).

## Project in One Line
Self-guided "How AI works" workshop (inference → agents → MCP → AI security) on a Hugo site, plus the `lab-app/` stack participants deploy (Ollama `qwen2.5:3b`, FastAPI agent, FastMCP server, nginx UI) to AKS via Helm.

## Stack
| Layer | Tech | Notes |
|---|---|---|
| Site | Hugo in `public.ecr.aws/k4n6m5h8/fortinet-hugo:latest` (Relearn 8, Hugo 0.165) | Config/theme in CentralRepo, not here |
| Lab app | `lab-app/` — compose profiles m1–m4, Helm chart `lab-app/helm/ai101` (`values-lab{1..4}.yaml`) | Ports: ollama 11434, agent 8001, mcp 8000, ui 8080 |
| Deploy | `.github/workflows/static.yml` → GitHub Pages on push to `main` | Template-managed; hand-edits lost |
| Plans | `plans/` (root) | `docs/` is gitignored and deleted by CentralRepo automation |

## Scope decisions
- Kubernetes (AKS + Helm) is the only deployment path. The Docker Compose path was cut 2026-09-24; `lab-app/compose/` is dev-only. Don't reintroduce Docker instructions or declare `deploymentPaths`.
- Participants run every command on the provided **Linux VM (the bastion)** — decided 2026-09-24. Call it "the bastion" (first use: "the bastion — the Linux VM provided for your session"); never "Cloud Shell" or "your laptop". Command fences use `run="bastion"`.

## Key Files
- `content/0N<Module>/_index.md` — concept page; `1_lab/index.md` — hands-on lab
- `content/09Reference/handouts/` — stale copy generated in ai-101; nothing here regenerates it (see Gotchas)
- `lab-app/images/agent/main.py`, `tools.py`, `mcp-server/server.py` — code the labs quote; keep excerpts in sync
- `lab-app/scripts/` — lab helper scripts referenced from content
- `instructor_content/` — instructor-only material
- `migration_log*.csv` — stale, not about this repo; ignore

## Build
```bash
docker run --rm -v "$PWD:/home/UserRepo" public.ecr.aws/k4n6m5h8/fortinet-hugo:latest build
```
No test suite; validate by rendering. Built URLs are flat (`02inference/1_lab.html`); Hugo minifies attributes unquoted.

## Authoring conventions
- Commands: ```bash {run="bastion"}, no `$` prompt, one command per block, preceded by a sentence. Output: ```output, introduced by "The output is similar to:". Tabs only for genuine alternatives. Render hooks live in CentralRepo (v26.3.an+). Reference-only menus (e.g. `2_lab_setup` §5 per-lab upgrades) get no `run=`. `collapse="true"` must be quoted.
- Output fences never use `bash`; use `output` (or `{lang="json"}`).
- Code quoted from `lab-app/` must match the file — labs ask readers to find lines in it.
- No `<-- comments` inside copyable fences.
- Authoring snippets in `.vscode/markdown.code-snippets` (`cmd`, `out`, `outj`, `outc`, `cmdout`, `notice`, `checkpoint`, `expand`, `ctrlc`, `kbd`) encode these conventions; keep them in sync when a convention changes. `.gitignore` un-ignores only that file and `.vscode/settings.json`.

## Gotchas
- Shortcodes/render hooks belong in CentralRepo; a same-named file in `layouts/` here silently shadows CentralRepo's.
- `main` requires `ci/jenkins/build-status` (0 approvals; squash/merge/rebase all allowed, verified 2026-09-24). Likely the same push-only Jenkins webhook gap as UserRepo: push the branch and let Jenkins build **before** opening the PR, or the check may never report.
- Any `helm upgrade` that changes agent values replaces the agent pod and kills its port-forward: follow with `kubectl rollout status deployment/ai101-agent` (not `kubectl wait --for=condition=Available`, which returns mid-rollout) and restart the forward before any `localhost:8001` call.
- Stop a specific port-forward with `pkill -f "port-forward svc/<name>"`, never `kill %N`: job numbers shift across labs and `%1` is the Ollama forward from setup.
- UI address: `kubectl get svc ai101-ui -o jsonpath='{.status.loadBalancer.ingress[0].ip}'` (LoadBalancer in values-lab2..4), not `az network public-ip` parsing; the IP can be empty for ~30 s after upgrade.
- Expected output must match `lab-app/` seed data (e.g. Alice Chen's manager is Bob Martinez, `seed.sql`) — reviewers caught invented output twice.
- Plan/log commits carry `[skip ci]`; merge PRs with `gh-merge-verify <pr> --repo FortinetCloudCSE/xperts-ai-101 --method squash -- --subject … --body …` so the token doesn't suppress the Pages deploy.
- `package.json`'s `hugo` script is dead (references `config.toml`/`docs/`).
- `gen_handouts.py`, `lint_paths.py`, `handout-pdf.yml`, `path-lint.yml` are **inert** here: they no-op without `deploymentPaths` in `scripts/repoConfig.json`, which this repo doesn't declare. The handout page's "CI fails if stale" notice is false in this repo.
