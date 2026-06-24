<div align="center">

# 📱 Mobile Engineering Agents

## Turn your AI coding agent into a Senior mobile engineer

A drop-in knowledge system that gives **Claude Code, Codex, Cursor, Windsurf, Gemini CLI, and Aider**
the judgment of an experienced mobile team — architecture, security, testing, and standards — so the
code they generate is production-grade, not just plausible.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![Platform](https://img.shields.io/badge/focus-iOS%20%7C%20Swift%20%7C%20SwiftUI-orange.svg)](#-whats-inside)
[![AI-ready](https://img.shields.io/badge/AI-Claude%20%C2%B7%20Codex%20%C2%B7%20Cursor%20%C2%B7%20Windsurf%20%C2%B7%20Gemini%20%C2%B7%20Aider-blueviolet.svg)](#-how-to-use)

[Quick Start](#-quick-start) · [What's Inside](#-whats-inside) · [The Agent Team](#-the-agent-team) · [How to Use](#-how-to-use) · [How It Works](#-how-it-works) · [Workflows](#-example-workflows)

</div>

---

## 💡 Why this exists

AI agents can write a lot of mobile code, fast. The bottleneck isn't typing — it's **engineering
judgment**: picking the right architecture, getting concurrency and error handling right, securing
data, and keeping the codebase maintainable as it grows.

> **Without this toolkit:** "Build me a login screen" → a Massive View Controller with the token in
> `UserDefaults` and no tests.
>
> **With it:** the agent acts as a Security Expert + SwiftUI Expert — OAuth2 + PKCE, Keychain
> storage, MVVM, typed errors, and unit tests — then self-reviews against a checklist.

This repo encodes that judgment as machine-loadable **agents, skills, workflows, checklists,
templates, prompts, standards, and architecture references**. Primary focus: **iOS / Swift /
SwiftUI**; secondary: **Android/Kotlin** and **Flutter**.

It is **not** a tutorial or handbook. It's an operational toolkit you point your AI agent at.

---

## ⚡ Quick Start

```bash
# 1. Clone it next to (or inside) your project
git clone https://github.com/sokpichdev/mobile-engineering-agents.git
```

There are two ways to drive it — and the everyday one needs **zero file paths**.

**Mode A — just describe the task** (the default). Tell your agent what you want in plain
language. The entry file routes it to the right experts and self-reviews automatically:

```text
> Build an Account Summary screen that loads /accounts and stores the auth token securely.
```

Behind the scenes that gets routed iOS Architect → SwiftUI → Networking → Security → Testing →
Code Reviewer — you didn't name a single file. See [How It Works](#-how-it-works).

**Mode B — name a file to steer it** (optional, for precision or to override the routing):

```text
> Read agents/ios_architect.md and act as that agent.
> Follow workflows/create_feature.md to build an Account Summary screen
  that loads /accounts, then self-review against checklists/code_review.md.
```

Either way, editors like **Cursor**, **Windsurf**, **Claude Code**, and **Gemini CLI** auto-load the
matching config file (`.cursorrules`, `.windsurfrules`, `CLAUDE.md`, `GEMINI.md`) so the defaults
apply with zero setup. Jump to [How to Use](#-how-to-use) for per-tool examples.

---

## 🗂️ Install into your own project

Two steps and you're done. After cloning, the session start banner fires automatically on
every Claude Code session — no further config needed.

### 1. Clone the toolkit inside your project

```bash
cd ~/Desktop/Git/DevDesign
git clone https://github.com/sokpichdev/mobile-engineering-agents.git .mobile-agents
```

This puts the whole toolkit in a hidden subfolder `.mobile-agents/` so it doesn't clutter
your project files. Add it to `.gitignore` if you don't want it committed:

```bash
echo ".mobile-agents/" >> .gitignore
```

### 2. Create entry-point files that import it

```bash
echo "@.mobile-agents/CLAUDE.md" > CLAUDE.md
```

The `@` syntax tells Claude Code to import that file's full contents. For Cursor and Windsurf,
do the same for their config files:

```bash
echo "@.mobile-agents/.cursorrules" > .cursorrules
echo "@.mobile-agents/.windsurfrules" > .windsurfrules
```

That's it. Open your project and the banner appears automatically at the start of every session:

```text
Mobile Engineering Agents — loaded ✓
14 agents · 31 skills · 12 workflows · 8 checklists

  Mode A — Full workflow  (new feature · API · architecture)
  Mode B — Quick fix      (bug · UI tweak · small change)

Choose a mode, or just describe your task.
```

The banner is driven by a `SessionStart` hook in `.mobile-agents/.claude/settings.json` —
it's included in the repo, so cloning is all you need.

> **Note:** The banner appears in Claude's first response. You can type anything to trigger
> it, or just describe your task directly — Claude will show the banner and auto-detect
> the mode (A or B) from your message at the same time.

### 3. (Optional) Show the banner instantly — Claude Code only

If you want the banner to appear in the terminal **before** you type anything, add this
alias to your `~/.zshrc` (or `~/.bashrc`):

```bash
alias claude-mobile='printf "\n\033[1;36mMobile Engineering Agents — loaded ✓\033[0m\n14 agents · 31 skills · 12 workflows · 8 checklists\n\n  Mode A — Full workflow  (new feature · API · architecture)\n  Mode B — Quick fix      (bug · UI tweak · small change)\n\nChoose a mode, or just describe your task.\n\n" && claude'
```

Then reload your shell and use `claude-mobile` instead of `claude`:

```bash
source ~/.zshrc
claude-mobile
```

This is purely optional — Cursor, Windsurf, and Gemini CLI don't support pre-session
terminal output, so the default behavior (banner on first response) is consistent across
all tools.

### 4. Keep the toolkit up to date

```bash
cd ~/Desktop/Git/DevDesign/.mobile-agents
git pull
```

---

## 📦 What's Inside

| Directory | What it gives your agent | Count |
|-----------|--------------------------|-------|
| 🤖 [`agents/`](agents/) | Loadable expert roles (architect, security, testing…) | 14 |
| 🧠 [`skills/`](skills/) | Deep, single-topic know-how (auth, websockets, caching…) | 31 |
| 🔄 [`workflows/`](workflows/) | Step-by-step procedures (build a feature, integrate an API…) | 11 |
| ✅ [`checklists/`](checklists/) | Objective, automatable review gates | 8 |
| 📐 [`standards/`](standards/) | Non-negotiable rules (coding, security, testing, git) | 7 |
| 🏛️ [`architecture/`](architecture/) | Reference designs with Mermaid diagrams | 6 |
| ✍️ [`prompts/`](prompts/) | Copy-paste prompts for common tasks | 10 |
| 🧩 [`templates/`](templates/) | Scaffolding with boilerplate Swift | 8 |
| 📲 [`examples/`](examples/) | Reference apps (banking, chat, CoffeeCraft, ecommerce, social) | 5 |

Plus [`AGENTS.md`](AGENTS.md) (orchestration), [`GLOSSARY.md`](GLOSSARY.md) (shared terms), and a
`README.md` index inside every directory.

---

## 🤖 The Agent Team

Each agent is a self-contained role: **purpose, responsibilities, hard rules, coding standards,
review checklist, common mistakes, and example tasks**. They're organized into four tiers that hand
off to each other (see [`AGENTS.md`](AGENTS.md)).

### 🧭 Strategy

- [System Design Expert](agents/system_design_expert.md) — large-scale client/server & cross-cutting design
- [iOS Architect](agents/ios_architect.md) — module boundaries, layering, tech decisions

### 🛠️ Implementation

- [SwiftUI Expert](agents/swiftui_expert.md) — view composition, state, navigation
- [Networking Expert](agents/networking_expert.md) — REST/GraphQL clients, retries, error mapping
- [WebSocket Expert](agents/websocket_expert.md) — realtime transport, reconnection, backpressure
- [Backend Integrator](agents/backend_integrator.md) — API contracts, DTO mapping, pagination

### 🛡️ Quality & Hardening

- [Security Expert](agents/security_expert.md) — Keychain, pinning, crypto, OWASP MASVS
- [Testing Expert](agents/testing_expert.md) — unit/integration/UI strategy
- [Performance Expert](agents/performance_expert.md) — startup, memory, battery, rendering
- [Accessibility Expert](agents/accessibility_expert.md) — VoiceOver, Dynamic Type, contrast
- [Refactoring Expert](agents/refactoring_expert.md) — safe, incremental improvement

### 🚦 Gate & Delivery

- [Code Reviewer](agents/code_reviewer.md) — correctness, style, risk gating
- [Release Manager](agents/release_manager.md) — versioning, signing, store submission
- [DevOps Expert](agents/devops_expert.md) — CI/CD, Fastlane, automation

---

## 🚀 How to Use

The pattern is the same everywhere: **describe the task and let it route** (Mode A), or **load a
specific agent/skill/workflow file to steer it** (Mode B). The per-tool examples below show the
explicit Mode B form, but in day-to-day use a plain-language request is enough.

<details>
<summary><b>Claude Code</b></summary>

`CLAUDE.md` loads automatically. Pull in a specific role or workflow:

```text
> Read agents/security_expert.md and act as that agent.
> Audit Sources/Auth for credential issues using checklists/security_review.md.
> Follow workflows/integrate_rest_api.md to add the /transactions endpoint.
```

</details>

<details>
<summary><b>OpenAI Codex</b></summary>

`AGENTS.md` is read automatically. Reference files in your prompt:

```text
Using agents/swiftui_expert.md and standards/swiftui_standards.md, build the
account summary screen described below.
```

</details>

<details>
<summary><b>Cursor</b></summary>

`.cursorrules` applies automatically. Add a file to context and prompt:

```text
@workflows/integrate_graphql.md implement the feed query with pagination.
```

</details>

<details>
<summary><b>Windsurf</b></summary>

`.windsurfrules` is applied by Cascade. Reference files in chat:

```text
@checklists/code_review.md review the open diff.
```

</details>

<details>
<summary><b>Gemini CLI</b></summary>

`GEMINI.md` loads automatically. Use `@path` to include files:

```text
@agents/testing_expert.md @standards/testing_standards.md write tests for AuthRepository.
```

</details>

<details>
<summary><b>Aider</b></summary>

Add files to the chat session:

```bash
aider --read agents/ios_architect.md --read standards/architecture_standards.md
```

</details>

---

## 🧭 How It Works

You describe a **task**; the toolkit handles the assignment. The entry file classifies your
request by its *primary deliverable* (architecture, UI, data, security, a test, a release), picks
the **entry agent** that owns it, and hands off down a tier chain that ends in a checklist
self-review. You don't pick the agent — the request does.

A few examples of how plain-language requests route (full table in [`AGENTS.md`](AGENTS.md)):

| You ask for… | Entry agent | Typical chain |
|--------------|-------------|---------------|
| A login / token flow | Security Expert | Architect → Security → Networking → Testing → Reviewer |
| A new screen or UI change | SwiftUI Expert | SwiftUI → Accessibility → Testing → Reviewer |
| A new/changed API integration | Backend Integrator | Backend → Networking → Security → Testing → Reviewer |
| "It's slow / janky" | Performance Expert | Performance → specialist → Testing |

**What loads automatically vs. on demand:** the entry files (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`,
`.cursorrules`, `.windsurfrules`) are loaded by your tool at startup. Everything else — `agents/`,
`skills/`, `standards/`, `workflows/`, `checklists/` — is pulled in by the agent itself *as the task
needs it*. You don't have to name those files; naming one (Mode B) is just how you override or
sharpen the routing. The multi-agent handoff for a real task looks like the
[Example Workflows](#-example-workflows) diagram below.

---

## 🔄 Example Workflows

Ready-made, end-to-end procedures — each with inputs, steps, validation, and acceptance criteria:

- 🏗️ **Build a feature end-to-end** — [`workflows/create_feature.md`](workflows/create_feature.md)
- 🌐 **Integrate a REST API** — [`workflows/integrate_rest_api.md`](workflows/integrate_rest_api.md)
- ⚡ **Add realtime with WebSockets** — [`workflows/integrate_websocket.md`](workflows/integrate_websocket.md)
- 🔐 **Implement authentication** — [`workflows/implement_authentication.md`](workflows/implement_authentication.md)
- 🛡️ **Run a security audit** — [`workflows/perform_security_audit.md`](workflows/perform_security_audit.md)
- 🚢 **Ship a release** — [`workflows/release_application.md`](workflows/release_application.md)

Behind the scenes, a non-trivial task flows through multiple agents:

```mermaid
flowchart LR
    R[Feature Request] --> A[iOS Architect]
    A --> U[SwiftUI Expert]
    U --> N[Networking Expert]
    N --> S[Security Expert]
    S --> T[Testing Expert]
    T --> C[Code Reviewer]
    C --> Done([Merge-ready])
```

---

## ✅ Best Practices

1. **Load the smallest sufficient context** — the specific agent/skill/workflow, not the whole repo.
2. **Chain agents** for real work: architect → implementer → reviewer.
3. **Always end with a checklist** — have the agent self-review against [`checklists/`](checklists/).
4. **Treat standards as non-negotiable** — reference [`standards/`](standards/) for consistent output.
5. **Prefer workflows over ad-hoc prompts** for anything you'll do more than once.

---

## 🧭 Design Principles

Every agent defaults to the same engineering values, so output looks like one team wrote it:

- **Clean Architecture + MVVM** and **SOLID** by default.
- **Security is a requirement, not an afterthought** (OWASP MASVS).
- **Testable, modular, observable** code with explicit, typed error handling.
- **Consistent standards** across sessions, tools, and contributors.

---

## 🤝 Contributing

Contributions of all sizes are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md). In short: keep
files focused, follow the section templates, cross-link instead of duplicating, and use
illustrative (not necessarily compilable) Swift that demonstrates the correct pattern.

### 🌱 Good First Issues

New to the project? These are scoped, beginner-friendly, and have clear acceptance criteria —
the perfect place to start:

👉 **[Browse `good first issue`s](https://github.com/sokpichdev/mobile-engineering-agents/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)**

Your first contribution in four steps:

1. **Pick an issue** from the list above and comment that you're taking it.
2. **Fork & branch** — `git checkout -b feat/<short-name>`.
3. **Make the change** following the [section templates](CONTRIBUTING.md#file-section-templates),
   then run `npm install && npm run lint`.
4. **Open a PR** with a [Conventional Commit](CONTRIBUTING.md#commit-convention) title
   (e.g. `feat(skills): add SwiftData storage skill`).

That's it — a maintainer will review and help you land it. 🚀

---

## 🗺️ Roadmap

- [ ] Kotlin/Compose and Flutter parity for the iOS-first skills.
- [ ] Machine-readable agent manifests (YAML front-matter) for automated routing.
- [ ] Expanded example apps with full test suites.
- [ ] Evaluations that score agent output against the checklists.
- [ ] Optional MCP server exposing skills as callable tools.

---

## 📄 License

[MIT](LICENSE) © Sok Pich — free to use, fork, and adapt.

<div align="center">

**If this makes your AI a better mobile engineer, give it a ⭐ and share it.**

</div>
