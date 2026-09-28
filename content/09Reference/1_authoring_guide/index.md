---
title: "Authoring Guide: Hugo Conventions"
linkTitle: "Authoring Guide"
weight: 1
---

This page is for lab authors, not participants — it's the single reference for the Hugo
conventions this repo uses when writing lab content: command/output blocks (including the
`chatbot` block for chat-UI prompts), notices, expand sections, and the VS Code snippets
that generate all of them. Most of these render hooks and shortcodes live in CentralRepo
(config, theme, shortcodes for every FortinetCloudCSE workshop, not just this one); this
page documents how to *use* them from `xperts-ai-101` content, not how they're implemented.

## Command blocks: `run="<target>"`

Add `{run="<target>"}` to a `bash`, `sh`, `shell` or `text` fence for a coloured header
badge above the normal highlighted, copyable block. Five targets are standard choices:

| Target | Header reads | Colour | Use for |
|---|---|---|---|
| `bastion` | Run on: Bastion | blue | Shell commands participants run on the bastion VM |
| `local` | Run on: Local | green | Commands run on the participant's own machine |
| `pod` | Run on: Pod | purple | Commands run inside a cluster pod |
| `browser` | Run on: Browser | orange | Actions taken in a web browser, not a shell |
| `chatbot` | Ask the chatbot | orange, FortiAI-Assist icon | Prompts typed into the lab app's chat UI |

Any other value falls back to a neutral grey badge reading "Run on: &lt;Target&gt;" —
useful for a one-off but not a standard choice authors should reach for on purpose.

```bash {run="bastion"}
kubectl get pods
```

**Rules:** no `$` prompt in the fence. One command per block. Precede every block with a
sentence saying what it does. Code quoted from `lab-app/` must match the file exactly —
labs ask readers to find specific lines by content. No `<!-- comments -->` inside a
copyable fence — participants would copy them.

Snippet: type `cmd` in a markdown file and hit Tab.

## `chatbot` blocks — for chat-UI prompts

Chat-UI prompts aren't shell commands, so use a `text` fence, not `bash`:

```text {run="chatbot"}
Who is in the Engineering department?
```

Source:

````markdown
```text {run="chatbot"}
Who is in the Engineering department?
```
````

This is the standard choice for every "enter this into the chatbot" instruction in this
repo — see `content/03Agents/1_lab/index.md`, `content/04MCP/1_lab/index.md` and
`content/05Security/1_lab/index.md` for real examples. Don't precede it with prose like
"Ask the chatbot:" or "Enter in the chat box:" — the badge already says that.

Snippet: type `chatbot` in a markdown file and hit Tab.

## Custom label, icon and color

Every block's header text, icon and colour are author-editable, on any target, with the
`label`, `icon` and `color` attributes. Use this for a one-off badge that isn't one of the
five standard targets above — most labs won't need this.

```text {run="chatbot" label="Ask FortiAI-Assist" icon="fas fa-robot" color="#7a3fc4"}
Summarize this alert and recommend a remediation.
```

Source:

````markdown
```text {run="chatbot" label="Ask FortiAI-Assist" icon="fas fa-robot" color="#7a3fc4"}
Summarize this alert and recommend a remediation.
```
````

- `label` — replaces the header text entirely (e.g. "Run on: Bastion" or "Ask the chatbot").
- `icon` — `terminal` (default for most targets), `fortiai` (the mark `chatbot` uses by
  default), or any [Font Awesome](https://fontawesome.com/search?ic=free) class string, e.g.
  `fas fa-robot`.
- `color` — any CSS colour (hex, named, `rgb()`) for the header background.

## Expected-output blocks

A separate `output` fence renders a muted/dashed panel labelled "Expected output", with no
shell syntax colouring and no copy button — so it can't be mistaken for something to paste.
Never fence output as `bash` — that gives it a copy button and command styling it shouldn't
have. Introduce it with "The output is similar to:".

````markdown
The output is similar to:

```output
NAME   READY   STATUS
```
````

Optional attributes:
- `lang="json"` (or any Chroma lexer name) — syntax-highlights the panel's content.
- `collapse="true"` (**must be quoted** — a bare `collapse=true` is silently ignored) —
  wraps the panel in the theme's expand widget, collapsed by default. Use for long output.

Snippets: `out` (plain), `outj` (JSON), `outc` (long/collapsed), `cmdout` (command +
output pair in one snippet).

**Expected output must come from real `lab-app/` code and seed data, never invented** —
reviewers have caught invented output twice. Example: Alice Chen's manager is Bob
Martinez, from `seed.sql` — don't guess a plausible-sounding name. Values that vary per
run (revision numbers, timestamps, pod suffixes, LLM response text) get "similar to"
phrasing, or `[...]` plus a prose description of what a successful result looks like,
rather than a fabricated literal value.

## Notices

Relearn's notice box, for anything that needs to stand out from the surrounding prose:

```markdown
{{% notice style="tip" title="Title" %}}
Text.
{{% /notice %}}
```

`style` is one of `tip`, `info`, `note`, `warning`, `important`. Rough guide used in this
repo: `info` for background/context, `tip` for an optional hint, `note` for something to
remember, `warning` for something that can break the lab if skipped.

Snippet: `notice`. There's also a `checkpoint` snippet — a pre-filled `tip` notice titled
"Checkpoint" for "you should now have X" callouts, used throughout Module 1.

## Expand (collapsible sections)

For answers, long detail, or anything a participant shouldn't see until they choose to:

```markdown
{{% expand title="Title" %}}
Content.
{{% /expand %}}
```

Snippet: `expand`.

## Tabs

Relearn's own tab widget (composes with a `title=` attribute on a fence) is for **genuine
alternatives** only — e.g. the same step shown for two different shells. Don't reach for it
to group unrelated content; it reads as "pick one of these," not "here's more detail."

## Keyboard shortcuts

```markdown
<kbd>Ctrl</kbd>+<kbd>C</kbd>
```

Snippets: `ctrlc` (pre-filled Ctrl+C, for stopping a blocking command like
`kubectl ... -w`), `kbd` (any single key).

## VS Code snippets — keeping them in sync

All of the above are backed by `.vscode/markdown.code-snippets` (`cmd`, `out`, `outj`,
`outc`, `cmdout`, `notice`, `checkpoint`, `expand`, `chatbot`, `ctrlc`, `kbd`). **When a
convention on this page changes, update that file to match** — it's the fastest way for an
author to stay consistent, and a snippet that produces the old pattern is worse than no
snippet at all. It's one of only two paths `.gitignore` un-ignores under `.vscode/` (the
other is `.vscode/settings.json`), so it's safe to edit and commit directly.

## Gotchas

- **`bash`/`sh`/`shell`/`text` fences with no `run=` are unaffected** — this is a pure
  opt-in convention, not a change to plain code fences elsewhere in the site.
- **Reference-only menus** (option lists that aren't meant to be run as shown, like the
  per-lab Helm upgrade table in [Kubernetes / Helm Setup](../../01Intro/2_lab_setup))
  get no `run=` attribute at all.
- **Shortcodes and render hooks belong in CentralRepo.** A same-named file in this repo's
  `layouts/` silently shadows CentralRepo's — e.g. a repo-local `render-codeblock-bash.html`
  would lose the whole `run=`/`chatbot`/`output` system, not just override one piece of it.
  Adding a new standard `run=` target, or changing a badge's fixed colour/icon, is a
  CentralRepo change (`layouts/partials/shortcodes/cmd-block.html`,
  `layouts/partials/custom-header.html`) and a new `fortinet-hugo` image — not something to
  attempt from this repo.
- **`static.yml` is template-managed** — hand-edits are lost on the next CentralRepo sync.
- Built URLs are flat (`02inference/1_lab.html`, not `02inference/1_lab/`), and Hugo writes
  attributes unquoted in the rendered HTML — don't let either surprise you when reading a
  built page's source.
