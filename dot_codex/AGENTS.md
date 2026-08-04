# Codex Engineering Guidelines

## Scope and precedence

- This global file defines cross-repository personal defaults; keep repository layout, exact project commands, architecture decisions, and review rules in the repository's own `AGENTS.md`.
- Before acting, identify every applicable instruction file from the repository root to the working directory. A closer `AGENTS.md` or `AGENTS.override.md` supplies the more specific rule for its subtree.
- Use `AGENTS.override.md` only for a temporary, deliberate replacement, and remove it when the exception ends.
- Keep instruction files concise, durable, and actionable. Put specialized workflows in referenced documentation or skills instead of expanding the global prompt.
- If applicable instructions conflict or a required command is unavailable, surface the conflict and its impact instead of silently changing the requirement.

## Workflow

1. **Establish the outcome.** Confirm the requested result, relevant constraints, and observable completion criteria; challenge a premise when a smaller or safer change would solve the real problem.
2. **Inspect before editing.** Read applicable instructions, `git status --short`, relevant source, tests, manifests, configuration, and documentation. Use `rg --files` and `rg -n '<symbol-or-behavior>'` before assuming a file or pattern is absent.
3. **Check history for non-trivial changes.** For feature or multi-file work in a Git repository, inspect coupling and intent with `git log --oneline --follow -- <file>` and `git log --stat -- <files...>`. Skip this for copy edits, renames, and one-line configuration changes.
4. **Plan proportionally.** Maintain a concise todo list for work with three or more meaningful steps, keep one step in progress, batch independent read-only discovery, and sequence dependent work.
5. **Research selectively.** Treat the repository as the primary source for local behavior. When APIs, security guidance, versions, or other unstable facts matter, consult current primary or official sources before planning the dependent change.
6. **Implement the smallest coherent change.** Match surrounding architecture and style, preserve unrelated user changes, and avoid opportunistic rewrites or dependency additions.
7. **Verify and review.** Run the narrowest relevant checks first, then the configured lint, type-check, test, and build commands justified by the change. Inspect `git diff --check` and the complete in-scope diff before reporting completion.

State assumptions only when they cannot be resolved from available context. Ask for direction when a missing decision would materially alter behavior, data, security, or public interfaces.

## Delegation

- When a concrete subtask can be completed independently, use a subagent whenever practical.
- Delegate only work with a clear scope, boundary, and expected output; a subagent must not change the overall task objective or expand its assigned scope.
- Configure every subagent with `model = "gpt-5.6-luna"` and `model_reasoning_effort = "max"`.

## Behavior-driven TDD

- For behavior changes, ALWAYS start from BDD: define Given/When/Then acceptance scenarios in a `.feature` file before implementation — unconditionally, regardless of whether the repository already uses Gherkin.
- Follow RED → GREEN → REFACTOR: add or update the focused test, run it and confirm the expected failure, write the minimum implementation to pass, then improve the design while keeping tests green.
- Every bug fix requires a regression test that fails for the reported defect before the implementation changes.
- Update existing acceptance scenarios whenever their tested behavior changes; tests and specifications must describe the same contract.
- Put formal tests only in the repository's established test directories such as `tests/`, `__tests__/`, or `spec/`. Run disposable probes inline with the shell or in an OS temporary directory, never as root-level test artifacts.
- Docs, configuration, rename, and copy-only changes do not require artificial unit tests; use focused syntax, schema, link, rendering, or command validation instead.

## Architecture and design

- Preserve the repository's established boundaries. For systems that use domain and application layers, keep dependencies pointing inward through these four responsibilities:
  1. **Domain:** business rules, value objects, and domain interfaces with no framework or infrastructure imports.
  2. **Application:** use cases that orchestrate domain behavior through ports and do not import infrastructure implementations.
  3. **Adapters and infrastructure:** persistence, transport, and external-service implementations that translate to and from application contracts.
  4. **Composition root:** entry-point wiring and dependency construction only, with no business logic.
- Define an interface in the layer that consumes it, inject implementations at boundaries, and prefer composition over inheritance.
- Choose the simplest implementation that fully meets current requirements; avoid speculative abstractions, configuration, and indirection. Use a repository only for a real data-access boundary and a strategy only for genuinely interchangeable algorithms. Two simple variants normally need a conditional, not a new abstraction hierarchy.
- Do not preserve backward compatibility: remove obsolete paths instead of adding compatibility layers, fallbacks, or migrations.
- Grow the system in layers: ship the smallest version that works end to end, then add each capability on top of a product that already works. Never trade a working product for unfinished complexity.
- Keep components modular with concerns clearly separated.
- Prefer established, well-maintained libraries when they reduce overall complexity or improve reliability; do not reimplement common functionality without a clear reason. Before writing your own implementation or adding a package, check whether a dependency already in the project provides the capability — consult its documentation and types rather than assuming it lacks one.
- Make architectural decisions for the long term; do not accept a stopgap that only works for now and is meant to be replaced later.
- Do not impose four layers on scripts, documentation, small utilities, or a localized change that already fits a simpler established design.
- Keep functions cohesive and normally below 50 lines, but do not split a readable unit merely to satisfy a line count.

## Interface design

Apply these four principles from Robin Williams's *The Non-Designer's Design Book* to every interface you build or review:

- **Proximity.** Group related elements and space apart unrelated ones; distance itself encodes relationship, and whatever shares a visual group is read as one unit.
- **Alignment.** Give every element a visual connection to at least one other along shared edges or a grid; nothing is placed arbitrarily.
- **Repetition.** Use one consistent visual form per kind of element, and reuse that form wherever that kind recurs.
- **Contrast.** Make different kinds of elements visibly different. Users read visual similarity as functional equivalence: elements that look alike are assumed to be the same kind. A shared form across distinct concepts, or a distinct form for one concept, misleads users before they ever interact.

## Code quality

- Match the surrounding code before applying personal preferences. Use descriptive names, strong types, guard clauses, and named constants where they clarify intent.
- Avoid generated-code noise: redundant narration comments, speculative helpers, unnecessary defensive checks in trusted paths, broad `try/catch` blocks, type-system bypasses such as `any`, and formatting inconsistent with nearby code.
- Comment why a non-obvious constraint exists, not what the code already states. Update public API and behavior documentation in the same change.
- Handle expected failures at the appropriate boundary with actionable messages; never swallow errors. Treat unhandled promise rejections as production failures.
- Never hardcode credentials, tokens, or private data. Do not emit secrets in commands, logs, fixtures, or examples.
- Do not add emojis to generated content, code, commands, paths, or error messages unless explicitly requested.

## Toolchain defaults

- Discover manifests, lockfiles, pinned tool versions, and existing scripts before choosing commands. A repository-specific toolchain overrides these global defaults.
- Change dependency declarations through the ecosystem CLI rather than editing manifests directly, for example `pnpm add` / `pnpm remove`, `uv add` / `uv remove`, and `cargo add` / `cargo remove`.
- For Node.js, use the pinned package manager; when the repository has no choice, use `pnpm`. Prefer Biome with two-space indentation for a new, unconfigured formatter/linter, but do not migrate an existing stack without a request.
- Document public JavaScript APIs with JSDoc when types and names do not already communicate the contract.
- For Python, use `uv`, add explicit type hints and docstrings to public APIs, and follow the repository's configured PEP-compatible formatter, linter, and type checker.
- Run only commands supported by the repository. Typical commands are `pnpm test`, `pnpm lint`, `pnpm build`, and `uv run pytest`; inspect scripts and configuration rather than assuming all of them exist.

## Review and completion

- Review every in-scope diff for correctness, regressions, security, error paths, and unintended public-interface changes.
- For non-trivial code changes, run `codex review --uncommitted` when Codex is available and the working-tree scope is unambiguous; address verified findings and rerun relevant checks. Skip the independent review for docs, copy, rename, and one-line configuration changes.
- A task is complete only when the requested behavior and acceptance criteria are met, relevant checks pass, `git diff --check` is clean, documentation is synchronized, and remaining risks or unrun checks are disclosed.
- Report the outcome first, followed by changed files, exact verification commands with results, and any residual risk. Never claim a check was run when it was not.
- If context is compacted, preserve the modified-file list, key decisions, executed checks, and unresolved work before continuing.

## Git and delivery

- Treat a dirty working tree as user-owned state: do not discard, overwrite, stage, or include unrelated changes.
- Prefer `git-agent` for commit planning and message generation when it is available and its behavior is appropriate for the repository; fall back to standard Git when it is unavailable or the repository requires a different workflow.
- Do not run destructive Git commands or rewrite shared history unless the user explicitly requests the exact operation.
- Create commits, push branches, open pull requests, or merge only when explicitly requested. These actions change shared state and are not implied by a code-edit request.
- When commits are requested, make each one an atomic logical unit with a conventional-commit title that is entirely lowercase and under 50 characters.
- Run applicable lint, type-check, test, and build checks before committing or publishing. Use merge commits for requested PR merges unless a closer repository rule requires another strategy.
- Follow least-privilege security practices and never bypass hooks, branch protection, reviews, or failing checks to make delivery succeed.

## AGENTS.md authoring standard

- Every sentence must add unique operational value; remove duplicated, generic, or contradictory guidance.
- Emphasize hard-to-discover architecture, invariants, and failure modes, including the constraint or trade-off that explains each non-obvious rule.
- Include repository layout, exact setup/build/test/lint commands, review expectations, and an executable definition of done at the narrowest applicable directory.
- Keep formatting-only rules in automated tooling. Put behavioral review rules in `## Code Review Rules`, stating what to flag, why it matters, and the safe alternative or exception.
- Prefer nested `AGENTS.md` files for subtree-specific rules instead of accumulating exceptions in the root; do not duplicate parent guidance.
- Keep the combined instruction chain comfortably below Codex's default 32 KiB limit. Verify discovery from the target repository with:

  ```bash
  codex --ask-for-approval never "List the active instruction files, then summarize them in precedence order."
  ```
