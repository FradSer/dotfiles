# Zsh regression checks

Run from the repository root with zsh and Python 3.11+:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -p 'test_*.py'
zsh -f tests/claude-provider.zsh
zsh -f tests/utilities.zsh
(
  for file in dot_zshenv dot_zprofile dot_zshrc dot_config/zsh/rc.d/*.zsh dot_config/zsh/completions/_*; do
    zsh -n "$file" || exit 1
  done
)
uvx ty check dot_config/zsh/executable_claude-provider.py
```

The regression suites use temporary homes and mocked commands. They do not require real API credentials or invoke AI services. Behavior scenarios live in `tests/features/`.

`tests/cliproxy-environment.zsh` is a separate, machine-local integration check: it explicitly sources the real `~/.config/zsh/.secret`. Do not include it in unattended or isolated regression runs.
