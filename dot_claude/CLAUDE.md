# Claude Development Guidelines

## CRITICAL: Git Commits

NEVER use git add/git commit via Bash. When asked to commit, ALWAYS invoke the `/git:commit` skill via the Skill tool. Do NOT run `git status`, `git diff`, or `git log` for commit purposes — the skill handles everything.

## CRITICAL: Asking the User

ALWAYS use the `AskUserQuestion` tool when you need to ask the user a question. Do NOT ask questions in plain text output.

## Core Principles

- BDD-driven TDD: define Given/When/Then scenarios in `.feature` files first → RED test → GREEN code → REFACTOR
  1. New behavior requires a `.feature` scenario first
  2. When updating tests, update the corresponding `.feature` to match
- Clean Architecture (4 layers, dependencies point inward only):
  1. Interfaces defined in the consuming layer, not the implementing layer
  2. Domain layer: zero external imports — pure interfaces and value objects only
  3. Application layer: orchestrates via interfaces, never imports infrastructure
  4. Composition Root (cmd layer): wiring only, no business logic
- Challenge the premise before implementing: is the stated problem the actual problem?
- Match complexity to actual scale — 2 variants = if/switch, not an abstraction layer
- Web search for latest best practices before planning and implementing
- Verify your own work: run tests and typecheck after completing changes

## Code Quality

IMPORTANT: Do not generate AI code slop:
- Extra comments inconsistent with file style or that a human wouldn't add
- Unnecessary defensive checks/try-catch in trusted codepaths
- Casts to `any` to bypass type issues
- Style inconsistent with surrounding code

### Testing

- Formal tests in `tests/`, `__tests__/`, or `spec/` only — no temp scripts in project root
- Run quick validations directly with bash

## Tooling

- Formatter/Linter: Biome (not ESLint/Prettier), 2-space indentation
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
