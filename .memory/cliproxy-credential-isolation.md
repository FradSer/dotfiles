---
name: CLI Proxy API credential isolation
description: Keep proxy credentials provider-scoped and derive URLs from one host and port.
type: decision
---

## Why

Global OPENAI variables redirect unrelated clients. Duplicate TOKEN and API_KEY variables can diverge. Hardcoded provider ports ignore the configured port.

## How to apply

Keep CLIPROXYAPI_TOKEN as the sole shell credential in the unmanaged local secrets file. Derive CLIPROXYAPI_BASE_URL with /v1 from CLIPROXYAPI_HOST and CLIPROXYAPI_HOST_PORT. Claude provider URLs use the same host and port without /v1. Map OPENAI variables only for individual commands. Resolve provider token_var against the exported process environment in Python before constructing the child environment, not via zsh dynamically scoped locals that can shadow credential names. Parse extra_flags assignments before expanding their values so spaces remain data. Management credentials are separate from inference credentials.

Run `zsh tests/cliproxy-environment.zsh` on the configured workstation. The secrets assertions intentionally depend on local configuration and must never print credential values.

## Related

- [[../tests/features/cliproxy-environment.feature]]
