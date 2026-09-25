# CLAUDE.md — xperts-ai-101

> Global prefs: `~/.claude/CLAUDE.md`. Ecosystem: CentralRepo (Hugo image, theme, shortcodes, render hooks), UserRepo (template this was cloned from), faig-training-workshop (Day 2 follow-on).
> **On demand — [plans/claude/reference.md](plans/claude/reference.md):** stack/ports and key files (touching build, deploy or lab-app) · lab command patterns (writing or editing any lab) · CI/merge/image detail (opening or merging a PR, or a stale site or preview).

Self-guided "How AI works" workshop (inference → agents → MCP → AI security). A Hugo site, plus the `lab-app/` stack (Ollama `qwen2.5:3b`, FastAPI agent, FastMCP server, nginx UI) that participants deploy to AKS via the Helm chart `lab-app/helm/ai101`.

## Build
```bash
docker run --rm -v "$PWD:/home/UserRepo" public.ecr.aws/k4n6m5h8/fortinet-hugo:latest build
```
No test suite; validate by rendering. Built URLs are flat (`02inference/1_lab.html`), and Hugo writes attributes unquoted.

## Scope
- Kubernetes (AKS + Helm) is the only deployment path; the Docker path was cut 2026-09-24. Never reintroduce Docker instructions or declare `deploymentPaths`.
- Participants run every command on **the bastion** (on first use: "the bastion (the Linux VM provided for your session)"). Never say "Cloud Shell" or "your laptop".
- Plans live in root `plans/`. `docs/` is gitignored and deleted by CentralRepo automation.

## Authoring
- Commands go in ```` ```bash {run="bastion"} ````: no `$` prompt, one command per block, preceded by a sentence. Output goes in ```` ```output ```` (`{lang="json"}` for JSON), introduced by "The output is similar to:". Never fence output as `bash`. Tabs are only for genuine alternatives. `collapse="true"` must be quoted.
- Code quoted from `lab-app/` must match the file (labs ask readers to find lines). Expected output must come from lab-app code and seed data, never invented.
- No `<-- comments` inside copyable fences.
- When a convention changes, update `.vscode/markdown.code-snippets` to match.

## Gotchas
- Shortcodes and render hooks belong in CentralRepo; a same-named file in `layouts/` here silently shadows CentralRepo's.
- `static.yml` is template-managed; hand-edits are lost.
- A `helm upgrade` that changes agent values kills the agent port-forward. Use `kubectl rollout status`, then restart the forward. Stop forwards with `pkill -f`, never `kill %N`.
- Before opening a PR, push and wait for `ci/jenkins/build-status`. Merge via `gh-merge-verify … --method squash -- --subject … --body …` because plan commits carry `[skip ci]`.
