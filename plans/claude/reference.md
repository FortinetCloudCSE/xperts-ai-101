# xperts-ai-101 — on-demand reference

Linked from `CLAUDE.md`. Read the matching section when the trigger applies.

## Stack (read when touching build, deploy or lab-app)

| Layer | Tech | Notes |
|---|---|---|
| Site | Hugo in `public.ecr.aws/k4n6m5h8/fortinet-hugo:latest` (Relearn 8, Hugo 0.165) | Config, theme and shortcodes live in CentralRepo, not here |
| Lab app | `lab-app/`: Helm chart `lab-app/helm/ai101` (`values-lab{1..4}.yaml`); `lab-app/compose/` (profiles m1–m4) is dev-only | Services `ai101-ollama` 11434, `ai101-agent` 8001, `ai101-mcp-server` 8000, `ai101-ui` 8080 |
| Deploy | `.github/workflows/static.yml` → GitHub Pages on push to `main` | Template-managed by CentralRepo `batch_repo_update.py`; hand-edits are lost |

## Key files

- `content/0N<Module>/_index.md` is the concept page; `1_lab/index.md` is the hands-on lab.
- `lab-app/images/agent/main.py`, `tools.py`, `seed.sql`, `mcp-server/server.py`: code and data the labs quote.
- `lab-app/scripts/`: lab helper scripts referenced from content.
- `instructor_content/`: instructor-only material.
- `migration_log*.csv`: stale, not about this repo; ignore.
- `.vscode/markdown.code-snippets`: authoring snippets `cmd`, `out`, `outj`, `outc`, `cmdout`, `notice`, `checkpoint`, `expand`, `ctrlc`, `kbd`. `.gitignore` un-ignores only it and `.vscode/settings.json`.

## Lab command patterns (read when writing or editing a lab)

- **Agent pod replacement:** any `helm upgrade` that changes agent values replaces the agent pod and kills its port-forward. Follow it with `kubectl rollout status deployment/ai101-agent`, then restart the forward before any `localhost:8001` call. Don't use `kubectl wait --for=condition=Available`: the Deployment is already Available mid-rollout, so it returns immediately.
- **Stopping a port-forward:** use `pkill -f "port-forward svc/<name>"`. `kill %N` targets the wrong job because job numbers shift across labs, and `%1` is the Ollama forward from setup.
- **UI address:** `kubectl get svc ai101-ui -o jsonpath='{.status.loadBalancer.ingress[0].ip}'` (the service is a LoadBalancer in values-lab2..4). Don't parse `az network public-ip` output; the `.[1]` order isn't guaranteed. The IP can be empty for about 30 s after an upgrade, so tell readers to re-run or `kubectl get svc ai101-ui -w`.
- **Expected output:** derive it from `lab-app/` code and seed data. Example: Alice Chen's manager is Bob Martinez (`seed.sql`). Reviewers caught invented output twice in 2026-09. Values that vary per run (revision, timestamps, pod suffixes, LLM text) are introduced with "similar to", or replaced with `[...]` plus a prose success check.
- **Reference-only menus** (e.g. `2_lab_setup` §5 per-lab upgrades, the §6 FortiAIGate example) get no `run=`; they aren't run as shown.
- **Chat-UI prompts:** put them in a copyable block, not inline code. Inline copy icons are disabled site-wide (`disableInlineCopyToClipBoard` in `scripts/repoConfig.json`).

## CI and merge detail

- **Jenkins check:** `main` requires `ci/jenkins/build-status` (0 approvals; squash, merge and rebase all allowed; verified 2026-09-24). The Jenkins webhook only sends push events, so push the branch and wait for the status **before** opening the PR, or the check may never report (same gap as UserRepo).
- **Skip-ci tokens:** plan and log commits carry `[skip ci]`. A squash merge that includes one suppresses the Pages deploy, so merge with `gh-merge-verify <pr> --repo FortinetCloudCSE/xperts-ai-101 --method squash -- --subject … --body …`.
- **Remote branch after a squash:** after a squash merge, the remote `jkopkoEdits` keeps pre-squash commits. Realign locally with `git reset --keep origin/main`; the next push needs `--force-with-lease` pinned to the old SHA.
- **Handout tooling is inert:** `gen_handouts.py`, `lint_paths.py`, `handout-pdf.yml` and `path-lint.yml` no-op without `deploymentPaths`, which this repo deliberately doesn't declare.
- **Dead npm script:** `package.json`'s `hugo` script is dead (it references `config.toml` and `docs/`).
- **Stale image on the site:** a deploy that runs minutes after a CentralRepo prod push can build with the previous image (ECR Public serves a stale `:latest`). Check the live `CloudCSE Version` and re-run with `gh workflow run static.yml`.
- **Stale local preview:** `fortihugorunner launch-server --pull-latest` (v0.7.5) didn't re-tag a stale local `fortinet-hugo:latest`. Use `fortihugorunner pull-image --env author-dev`, then restart the server.
