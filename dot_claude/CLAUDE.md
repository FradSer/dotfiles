# Claude Development Guidelines

## CRITICAL: Git Commits

NEVER use git add/git commit via Bash. When asked to commit, ALWAYS invoke the `/git:commit` skill via the Skill tool. Do NOT run `git status`, `git diff`, or `git log` for commit purposes — the skill handles everything.

## CRITICAL: Asking the User

ALWAYS use the `AskUserQuestion` tool when you need to ask the user a question. Do NOT ask questions in plain text output.

## Core Principles

- BDD-driven TDD: ALWAYS start from BDD — define Given/When/Then scenarios in `.feature` files first, unconditionally → RED test → GREEN code → REFACTOR
  1. New behavior requires a `.feature` scenario first
  2. When updating tests, update the corresponding `.feature` to match
  3. Every bug fix requires a regression test that fails before the fix
- Clean Architecture (4 layers, dependencies point inward only):
  1. Interfaces defined in the consuming layer, not the implementing layer
  2. Domain layer: zero external imports — pure interfaces and value objects only
  3. Application layer: orchestrates via interfaces, never imports infrastructure
  4. Composition Root (cmd layer): wiring only, no business logic
  5. Do not impose 4 layers on scripts, small utilities, or localized changes that fit a simpler established design
- Challenge the premise before implementing: is the stated problem the actual problem?
- Choose the simplest implementation that fully meets current requirements: match complexity to actual scale (2 variants = if/switch, not an abstraction layer), avoid speculative abstractions, configuration, and indirection
- Do not preserve backward compatibility: remove obsolete paths instead of adding compatibility layers, fallbacks, or migrations
- Grow the system in layers: start from the smallest version that works end to end, add each capability on top of a product that already works — never trade a working product for unfinished complexity
- Keep components modular with concerns clearly separated
- Prefer established, well-maintained libraries over reimplementing common functionality; check whether a dependency already in the project provides a capability (docs and types) before writing your own or adding packages
- Make architectural decisions for the long term: no stopgaps that only work for now and are meant to be replaced later
- Web search selectively: when APIs, versions, security guidance, or other unstable facts matter, check current sources before planning
- Verify your own work: run tests and typecheck after completing changes
- Fresh-agent audit for multi-file or core-logic changes: after self-verification, spawn a new agent with no implementation context to audit correctness. Skip for one-line config, copy, or rename edits.

## Code Quality

IMPORTANT: Do not generate AI code slop:
- Extra comments inconsistent with file style or that a human wouldn't add
- Unnecessary defensive checks/try-catch in trusted codepaths
- Casts to `any` to bypass type issues
- Style inconsistent with surrounding code
- Never hardcode credentials, tokens, or private data in code, logs, fixtures, or examples

### Testing

- Formal tests in `tests/`, `__tests__/`, or `spec/` only — no temp scripts in project root
- Run quick validations directly with bash

## Tooling

- Formatter/Linter: prefer Biome with 2-space indentation for new or unconfigured projects; do not migrate an existing stack without request
- NEVER edit dependency manifests directly. Use package manager CLI:
  - Node.js: `pnpm add` / `pnpm remove`
  - Python: `uv add` / `uv remove`
  - Swift: `swift package add-dependency`
  - Rust: `cargo add` / `cargo remove`
- Node.js: pnpm. Treat unhandled promise rejections as production failures.
- Python: uv. Explicit type hints on public APIs.

## Style

- MUST NOT use emojis in generated content, code, commands, file paths, or error messages unless explicitly requested
- On compact: preserve modified files list, key decisions, and test commands
- Reference external docs with `@path/to/file` instead of inlining content
