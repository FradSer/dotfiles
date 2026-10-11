---
name: zsh-bun-completion
description: Keep Bun's generated completion script local and manage its loader in the completion module.
type: decision
---

## Why

The installed shell loads ~/.bun/_bun. Replacing the shell entry point with the managed version must not remove Bun completion.

## How to apply

Manage the loading hook in dot_config/zsh/rc.d/05-compinit.zsh after compinit, before later completion plugins. Source ~/.bun/_bun only when readable and nonempty. Leave the generated script under Bun's ownership rather than copying it into chezmoi or adding another hook to .zshrc.

## Related

[[zsh-command-contracts]]
