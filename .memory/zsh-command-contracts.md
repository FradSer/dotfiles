---
name: zsh-command-contracts
description: Keep shell wrappers transparent and unsafe execution explicit.
type: decision
---

## Why

The zsh audit found wrapper exit statuses masked by terminal output, provider environment leaking into the parent shell, and completion mutating shared provider lists. Native command names should retain predictable behavior.

## How to apply

Select providers only through explicit leading `claude --provider NAME`, not dynamically recognized `--NAME` flags. Consume wrapper options only in a contiguous prefix, stopping at the first native argument: native option values such as `--system-prompt --yolo` must never enable permission bypass. Native-first calls must work even when provider configuration or its parser is unavailable. Keep provider environment changes scoped to a child shell, clear competing cloud backend selectors there, preserve command exit status, and emit terminal control sequences only to terminals. AI wrappers use safe native defaults; bypassing approvals requires explicit `--yolo`. Completion consumes provider data without appending to global state. Reload replaces the shell rather than repeatedly sourcing plugin initialization.

## Related

[[cliproxy-credential-isolation]]
