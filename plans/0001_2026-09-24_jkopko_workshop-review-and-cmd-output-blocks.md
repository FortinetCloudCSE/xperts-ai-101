# Plan: Workshop review + standard command/output blocks
Date: 2026-09-24
Owner: Jeff Kopko
Slug: workshop-review-and-cmd-output-blocks
Status: Proposed
Supersedes: none
Superseded-By: none
Plan File: plans/0001_2026-09-24_jkopko_workshop-review-and-cmd-output-blocks.md
Log File: none. If Phase 2 runs in CentralRepo, its own plan lives there.

## Goal
- Fix correctness defects that block or mislead a self-guided participant.
- Replace the tab-based "Command / Expected Output" pattern with one standard, visually distinct convention: **Run-on labelled command block → Expected-output block**. Ship it as CentralRepo render hooks so every workshop inherits it.
- Tighten pedagogy, wording and formatting across Modules 01–05.
- Onboard this repo with an ai-101-specific `CLAUDE.md`. The current file is UserRepo's template copied verbatim; see the Appendix.

## Context / Links
- Theme: Hugo Relearn **8.0.0**, Hugo **0.165.0** (`CentralRepo/Dockerfile:15`). Relearn's `render-codeblock.html` delegates to `partials/shortcodes/highlight.html`, which already honours a `title` attribute. So ```` ```bash {title="…"} ```` renders a titled block today with no theme change. [Likely — verify by render in Phase 2a]
- Highlight config (`CentralRepo/scripts/templates/hugo.jinja`): `noClasses=true`, `style=catppuccin-latte`. `markup.goldmark.parser.attribute.block` is unset. That doesn't matter for code-fence info-string attributes, which Hugo always parses. [Likely]
- Copy button: `themes/hugo-theme-relearn/assets/js/theme.js` `initCodeClipboard()` copies every `<code>` block verbatim. Nothing strips `$` prompts or excludes output. [Certain]
- Precedent: `pathtabs`/`pathtab` were upstreamed from ai-101 into CentralRepo (`CentralRepo/RELEASE_NOTES.md:181`). New shortcodes and render hooks go in CentralRepo, never as repo-local copies, because `local_copy.sh` would shadow them silently.
- Handout tooling: `scripts/gen_handouts.py` and `scripts/lint_paths.py` parse `tabs` and `tab` shortcodes. A markdown-native convention (fence attributes) keeps both simpler.

## Current state (measured 2026-09-24)

### Command/output presentation: three competing patterns
| Pattern | Where | Prompt? | Output fence |
|---|---|---|---|
| A. `tabs`: "<verb>" tab + "Expected Output" tab (`style="info"`) | ~12 pairs in labs, 4 in `2_lab_setup`, 10 in `1_k8s…` | no | ```` ```bash ```` (even JSON/plain text) |
| B. Bare ```` ```bash ```` then prose ("Expected: `qwen2.5:3b`") | ~40+ pairs across labs, `cloud-shell-web-preview` | no | none / inline prose |
| C. Full transcript with prompt | `1_k8s…:36` (`aiuser@vm-linux-aiuser10:~$ ./aks-create.sh`) | yes | mixed in |

Problems with tabs for this job:
- Output isn't an *alternative* to the command. It is sequential, and tabs are the widget for alternatives, such as a bash vs PowerShell version of the same step.
- Hiding output behind a click means participants skip the verification step.
- Output in an inactive tab drops out of print/PDF (the handouts are `outputs: ["html","print"]`) and is harder for screen readers. [Likely]
- Tab titles are free text ("Install Chart", "Verify", "Override code check"), so nothing is recognisable across pages.
- ```` ```bash ```` on output gives it shell syntax colouring, so output looks like a command.
- Pattern A is used for fewer than 25% of pairs, so the house style isn't followed anyway.

### Research consensus
Kubernetes docs, Google dev style guide and DigitalOcean guidelines converge on the same pattern:
- No `$` prompt in commands.
- Each command in its own block, preceded by a sentence.
- Output in a **separate, labelled, visually distinct** block, introduced by "The output is similar to:".
- `[...]` for elided lines.
- Show output only when the reader must verify something.

Copy tooling (sphinx-copybutton, Killercoda `{{exec}}`) makes output non-copyable and marks runnable blocks explicitly.

Sources:
- https://github.com/kubernetes/community/blob/main/contributors/guide/style-guide.md
- https://developers.google.com/style/code-syntax
- https://www.digitalocean.com/community/tutorials/digitalocean-s-technical-writing-guidelines
- https://sphinx-copybutton.readthedocs.io/en/latest/use.html
- https://killercoda.com/creators
- https://gohugo.io/render-hooks/code-blocks/

## Proposed convention

Authoring (plain markdown, no shortcode nesting):

````markdown
Pull the model list from Ollama:

```bash {run="bastion"}
curl -s localhost:11434/api/tags | jq -r '.models[].name'
```

The output is similar to:

```output
qwen2.5:3b
```
````

Rendered:
- **Command block**: a header bar with a terminal icon and a **"Run on: Bastion"** badge. The badge colour is fixed per target: bastion / local / pod / browser, keyed off `run=`. Normal bash highlighting and the copy button stay.
- **Output block** (```` ```output ````): muted/dashed styling and a fixed **"Expected output"** label, with no syntax colouring and **no copy button**, so it can't be mistaken for something to paste. Optional `{lang="json"}` gets highlighting inside the output panel. Optional `{collapse=true}` (or an automatic collapse above N lines) wraps long output in an `expand`.
- Optional `{run="bastion" title="…"}` keeps the Relearn title for multi-command steps.

Implementation lives in **CentralRepo**, not here:
- `layouts/_default/_markup/render-codeblock-output.html`: a new language, so it can't collide with any workshop.
- `layouts/_default/_markup/render-codeblock-bash.html` (and `-sh`, `-shell`): **pass-through** to the theme partial when `run` is absent. Existing workshops render byte-identically until they opt in.
- A small CSS block (+ ~10 lines of JS to suppress the copy button on `.cmd-output`) in the CentralRepo asset layer.
- Documented in CentralRepo `README.md` and UserRepo's authoring guide. Proven on UserRepo first, per its `CLAUDE.md`.

Rejected:
- **Keep tabs but standardise titles.** This fixes naming but keeps output hidden, print-lossy and semantically wrong.
- **Single `console` block with prompt/output tokenisation.** It's compact, but Chroma inline styles (`noClasses=true`) make prompt/output hard to style. It also needs custom copy-stripping JS, and it's less recognisable at a glance than two panels.
- **Paired `{{< cmd >}}…{{< output >}}` shortcodes.** These work, but add nesting that `gen_handouts.py`/`lint_paths.py` must parse, and authors can't preview them in any markdown viewer.
- **`{{exec}}` click-to-run.** There's no execution backend, so it's out of scope.

Weakest part of this proposal:
- It needs a CentralRepo change, a new container image, and a coordinated rollout before ai-101 can use it.
- Overriding `render-codeblock-bash.html` means a future Relearn upgrade that changes its codeblock hook won't flow through for bash blocks. Mitigated by delegating to the theme partial rather than copying it.
- Fallback if CentralRepo is slow: ship Phase 3 with the zero-change form (```` ```bash {title="Run on: bastion"} ```` + ```` ```text {title="Expected output"} ````). This works on today's image, and the later switch is a mechanical sed.

## Review findings (to fix)

### P0: blocks or misleads participants
1. `content/_index.md` is **untracked**. `git log --diff-filter=D` shows it deleted in `72a9c71`, so the published site has no home page body. Decide: commit it or drop it. [Certain]
2. Home page advertises two paths (Docker / Kubernetes) "chosen on the setup page", but:
   - No `deploymentPaths` is declared anywhere.
   - No Docker page exists.
   - The handout links `/01Intro/1_prereqs_docker` (a dead link).
   Either declare the paths and write the Docker page, or cut Docker from the home page. [Certain]
3. Dead links to `/01Intro/2_prereqs_k8s` (real page: `2_lab_setup`) at `09Reference/_index.md:15` and `handout-k8s/index.md:1178`. [Certain]
4. The handout is stale against its source: it has a New Session step and screenshot that are gone from `2_lab_setup`. Regenerate it via `gen_handouts.py`. [Likely]
5. `03Agents/1_lab/index.md:190-211`: the numbered "loop code" is a paraphrase, so line numbers don't match `lab-app/images/agent/main.py:206-246`. The "identify in the actual file" exercise breaks. [Certain]
6. `02Inference/_index.md:189-199, 301-302` claims `top_p: 0.9` / `max_tokens: 512` are workshop defaults. No script sends them. [Certain]
7. The uncommitted diff in `1_k8s_deploy_and_concepts/index.md`:
   - The typo fixes are good.
   - It also removes three ```` ```bash ```` fences. Two indented commands become plain list text, which loses the copy button.
   Confirm this is intentional, and re-fence if not. [Certain it removes them; intent unknown]
8. `2_lab_setup/index.md:147-156`: `<-- Execute in Lab N` notes sit inside copyable fences and break the pasted command. [Certain]
9. `1_k8s…:17` says "At no point is access to Azure required", then runs `az aks list`. `aks-create.sh` isn't in the repo; presumably it's pre-staged on the VM, and the page should say so. [Likely]

### P1: pedagogy
- The 954-line K8s fundamentals page (juiceshop / kubernetes-bootcamp) never connects to the AI stack.
  - Add a bridge section: "the `ai101` chart you deploy next is the same Deployment/Service/Namespace objects".
  - Split the page into (a) cluster deploy and (b) K8s concepts.
  - Add intermediate checkpoints; currently there are only review questions at the end.
- FortiAIGate, Input Guard and AI Flow appear undefined in every lab. Add one "What is FortiAIGate" definition box at first use and link it from later labs.
- The execution environment is called "Linux VM", "Cloud Shell" and "your laptop" on different pages. Pick one term, define it once, and have `run=` badges enforce it.
- Temperature 0 is described as "same output every time". Soften to "usually reproducible". [Likely]
- `02Inference/1_lab` Step 1 re-runs `helm upgrade` for Ollama without saying why.
- Time estimates exist only on the home page. Add them to module intros, including setup.
- `05Security/1_lab:99-104`: `chars_exfiltrated: 67` looks like an unrun placeholder. Replace it with real output. [Guessing]

### P2: wording/format
- JSON output fenced as `bash`; `json` is used zero times in labs. This is resolved by the `output {lang=json}` convention.
- Typos: "a the AKS cluster", "Github" → "GitHub", a stray quote at `1_k8s…:17`.
- Normalise `title="Verify"%}}` spacing, curly vs straight apostrophes, and notice-style usage (info/note/tip/warning meanings).
- Fragile `awk -F- '{print $4}'` resource-group parsing in labs 03/04. Replace it with a `kubectl`/`az` query or a pre-set env var.

## Plan
- [ ] **Phase 0: Onboard.** On approval, replace `CLAUDE.md` with the Appendix draft. Seed project memory.
- [ ] **Phase 1: P0 fixes** in this repo (items 1–9 above). No CentralRepo dependency.
- [ ] **Phase 2: CentralRepo** (separate repo, separate plan file there, own worktree):
  - [ ] 2a. Render-verify that ```` ```bash {title=…} ```` works on the current image (the fallback path).
  - [ ] 2b. Add `render-codeblock-output.html`, pass-through `render-codeblock-{bash,sh,shell}.html` with `run=` badge, CSS, and copy-suppression JS.
  - [ ] 2c. Prove it on UserRepo with a demo page, built on the `dev` image variant.
  - [ ] 2d. README + RELEASE_NOTES. Publish the image.
- [ ] **Phase 3: Convert content** here: every tabbed command/output pair and every bare command+prose pair → `run=` + `output` blocks.
  - Drop output blocks that verify nothing, per Google guidance.
  - Strip the `$` prompt from `1_k8s…:36`.
  - Regenerate handouts. Run `lint_paths.py`.
- [ ] **Phase 4: P1/P2 pedagogy and wording** edits, module by module.
- [ ] Build with the container (`docker run … fortinet-hugo build`) and spot-check rendered pages at each phase. `/code-review low` before each commit.
- [ ] Close-out: RELEASE_NOTES (if adopted), promote decisions to `CLAUDE.md`, Status → Complete.

## Implementation Method
**Hybrid**:
- Phase 0–1 run direct in-conversation (small, targeted).
- Phase 2 runs in a **tmux session in a CentralRepo worktree**. It carries high blast radius (every workshop) and needs the dev image.
- Phase 3–4 run as a **Workflow fan-out**, one agent per module (01, 02, 03, 04, 05+09), all against the locked convention. They sync at a single build, handout regen and review.
- Phase 3 can start on the fallback syntax if Phase 2 stalls.

## Plan Changes
- (none)

## Decisions & Commentary
- Output is sequential, not alternative, so tabs are the wrong widget. Commands and output become labelled blocks in reading order.
- Use render hooks rather than shortcodes: authors write plain markdown, and the handout generator and linter stay shortcode-agnostic.
- The `bash` hook is pass-through when `run` is absent, so there are zero visual changes for workshops that don't opt in.

## Files Changed
- (none yet)

## Session Summary
- (write at end)

## Promotion
- [ ] `Decisions & Commentary` walked
- [ ] Durable facts promoted to `CLAUDE.md`
- [ ] `Status:` set to `Complete`

## Follow-ups
- [ ] Backport the convention to `ai-101`, `k8s-101-workshop` and `faig-training-workshop` after UserRepo proof.

## Risks / Open Questions
- Does Relearn 8's copy button attach to blocks rendered by a custom hook, and can it be suppressed per block without forking `theme.js`? Verify in 2b.
- Docker path: build it or cut it? This is the owner's call; it changes Phase 1 scope significantly.
- Is the uncommitted fence removal in `1_k8s…` intentional?
- Who owns CentralRepo image publishing and timing? Phase 3 waits on it unless the fallback is used.

## Appendix: draft `CLAUDE.md` for this repo (not yet written; replaces the copied UserRepo file)

```markdown
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

## Key Files
- `content/0N<Module>/_index.md` — concept page; `1_lab/index.md` — hands-on lab
- `content/09Reference/handouts/` — **generated** by `scripts/gen_handouts.py`; never hand-edit
- `lab-app/images/agent/main.py`, `tools.py`, `mcp-server/server.py` — code the labs quote; keep excerpts in sync
- `lab-app/scripts/` — lab helper scripts referenced from content
- `instructor_content/` — instructor-only material
- `migration_log*.csv` — stale, not about this repo; ignore

## Build
docker run --rm -v "$PWD:/home/UserRepo" public.ecr.aws/k4n6m5h8/fortinet-hugo:latest build
No test suite; validate by rendering. Built URLs are flat (`02inference/1_lab.html`); Hugo minifies attributes unquoted.

## Authoring conventions
- Commands: ```bash {run="bastion"}, no `$` prompt, one command per block, preceded by a sentence. Output: ```output, introduced by "The output is similar to:". Tabs only for genuine alternatives. (Pending plan 0001 / CentralRepo render hooks.)
- Output fences never use `bash`; use `output` (or `{lang="json"}`).
- Code quoted from `lab-app/` must match the file — labs ask readers to find lines in it.
- No `<-- comments` inside copyable fences.

## Gotchas
- Shortcodes/render hooks belong in CentralRepo; a same-named file in `layouts/` here silently shadows CentralRepo's.
- Merge strategy + Jenkins push-only webhook: assumed same as UserRepo (rebase only; push branch before opening PR) — VERIFY branch protection before adopting.
- `package.json`'s `hugo` script is dead (references `config.toml`/`docs/`).
- Handout regen + `lint_paths.py` run in CI (`handout-pdf.yml`, `path-lint.yml`); stale handouts fail CI.
```
