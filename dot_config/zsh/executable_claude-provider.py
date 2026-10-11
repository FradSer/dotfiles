#!/usr/bin/env python3
"""Claude provider management; requires Python 3.11+ for tomllib."""
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
import tempfile
from urllib.parse import urlsplit
try:
    import tomllib
except ImportError:
    print('Claude provider management requires Python 3.11+ (tomllib)', file=sys.stderr)
    sys.exit(1)

FIELDS = {'url', 'token_var', 'haiku_model', 'sonnet_model', 'opus_model',
          'fable_model', 'extra_flags', 'key'}


def load(path: Path) -> dict:
    data = tomllib.loads(path.read_text()) if path.exists() else {}
    providers = data.get('provider', {})
    if not isinstance(providers, dict):
        raise ValueError('Invalid provider table')
    for name, fields in providers.items():
        if not re.fullmatch(r'[A-Za-z0-9_-]+', name) or not isinstance(fields, dict):
            raise ValueError('Invalid provider name or table')
        for field, value in fields.items():
            values = value if field == 'extra_flags' and isinstance(value, list) else [value]
            if field not in FIELDS or any(not isinstance(item, str) or '\0' in item for item in values):
                raise ValueError('Invalid provider field')
        token = fields.get('token_var', '')
        if token and not re.fullmatch(r'[A-Za-z_][A-Za-z0-9_]*', token):
            raise ValueError('Invalid token variable name')
    return providers


def expand(value: str) -> str:
    return re.sub(r'\$\{([A-Za-z_][A-Za-z0-9_]*)\}|\$([A-Za-z_][A-Za-z0-9_]*)',
                  lambda match: os.environ.get(match[1] or match[2], ''), value)


ALLOWED_FLAGS = {'CLAUDE_CODE_ATTRIBUTION_HEADER', 'CLAUDE_CODE_AUTO_COMPACT_WINDOW',
                 'CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC', 'CLAUDE_CODE_EFFORT_LEVEL',
                 'CLAUDE_CODE_MAX_CONTEXT_TOKENS'}


VARIABLE = re.compile(r'\$\{([A-Za-z_][A-Za-z0-9_]*)\}|\$([A-Za-z_][A-Za-z0-9_]*)')


def assignments(fields: dict) -> list[str]:
    flags = fields.get('extra_flags', [])
    try:
        values = flags if isinstance(flags, list) else shlex.split(flags)
    except ValueError:
        raise ValueError('Invalid provider extra_flags quoting') from None
    for assignment in values:
        name, separator, _ = assignment.partition('=')
        if not separator or name not in ALLOWED_FLAGS:
            raise ValueError('Provider extra_flags may only set supported Claude tuning variables')
    return values


def validate_url(value: str) -> None:
    try:
        url = urlsplit(value)
        if url.scheme not in ('http', 'https') or not url.hostname or url.username or url.password:
            raise ValueError
        if any(character.isspace() for character in url.netloc):
            raise ValueError
        url.port
    except ValueError:
        raise ValueError('Provider requires an HTTP(S) URL with a valid host and port and no embedded credentials') from None


def validate_static(fields: dict) -> None:
    if 'key' in fields:
        raise ValueError('Inline keys are unsupported; remove key and use token_var')
    if not fields.get('token_var'):
        raise ValueError('Provider requires token_var')
    assignments(fields)
    value = fields.get('url', '')
    if not VARIABLE.search(value):
        validate_url(value)
    elif not (VARIABLE.match(value) and '://' not in value):
        # Use neutral placeholders to check literal structure without editor secrets.
        candidate = VARIABLE.sub('template', value)
        scheme, separator, rest = candidate.partition('://')
        if separator and scheme == 'template':
            candidate = 'https://' + rest
        candidate = candidate.replace(':template', ':443')
        validate_url(candidate)


def validate_selected(fields: dict) -> None:
    validate_static(fields)
    validate_url(expand(fields.get('url', '')))


def environment(fields: dict) -> dict[str, str]:
    validate_selected(fields)
    token = os.environ.get(fields['token_var'], '')
    if not token:
        raise ValueError('Provider token variable is unset or empty')
    result = os.environ.copy()
    for name in ('CLAUDE_CODE_USE_VERTEX', 'CLAUDE_CODE_USE_BEDROCK', 'CLAUDE_CODE_USE_FOUNDRY',
                 'CLAUDE_CODE_OAUTH_TOKEN', 'ANTHROPIC_BASE_URL', 'ANTHROPIC_AUTH_TOKEN',
                 'ANTHROPIC_API_KEY', 'CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC'):
        result.pop(name, None)
    result.update(ANTHROPIC_BASE_URL=expand(fields['url']), ANTHROPIC_AUTH_TOKEN=token)
    for model in ('haiku', 'sonnet', 'opus', 'fable'):
        name = f'ANTHROPIC_DEFAULT_{model.upper()}_MODEL'
        result.pop(name, None)
        value = expand(fields.get(f'{model}_model', ''))
        if value:
            result[name] = value
    for assignment in assignments(fields):
        name, _, value = assignment.partition('=')
        result[name] = expand(value)
    return result


def run(path: Path, args: list[str]) -> None:
    selected = None
    unsafe = False
    while args:
        if args[0] == '--yolo':
            unsafe = True
            args = args[1:]
        elif args[0] == '--provider':
            if selected is not None or len(args) < 2 or not args[1] or args[1].startswith('-'):
                raise ValueError('Usage: claude --provider NAME (select one provider)')
            selected = args[1]
            args = args[2:]
        else:
            break
    child = os.environ.copy()
    if selected is not None:
        providers = load(path)
        if selected not in providers:
            raise ValueError('Unknown provider; use claude-provider list')
        child = environment(providers[selected])
    if unsafe:
        args = ['--dangerously-skip-permissions', *args]
    os.execvpe('claude', ['claude', *args], child)


def records(providers: dict) -> None:
    for name, fields in sorted(providers.items()):
        sys.stdout.write(f'{name}\0invalid\0{"1" if "key" in fields else ""}\0')
        for field, value in fields.items():
            if field == 'key':
                continue
            if isinstance(value, list):
                value = shlex.join(value)
            sys.stdout.write(f'{name}\0{field}\0{value}\0')


def edit(path: Path) -> None:
    editor = shlex.split(os.environ.get('VISUAL') or os.environ.get('EDITOR') or 'vi')
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, filename = tempfile.mkstemp(prefix='.claude-providers-', suffix='.toml', dir=path.parent)
    temporary = Path(filename)
    try:
        with os.fdopen(fd, 'w') as stream:
            stream.write(path.read_text() if path.exists() else '[provider]\n')
        subprocess.run([*editor, filename], check=True)
        providers = load(temporary)
        for fields in providers.values():
            validate_static(fields)
        os.chmod(temporary, 0o600)
        os.replace(temporary, path)
        print('Only the target file changed. To persist it in chezmoi source, run:')
        print('chezmoi add ' + shlex.quote(str(path)))
    finally:
        temporary.unlink(missing_ok=True)


def show(name: str, fields: dict) -> None:
    print(f'Provider: {name}')
    if 'key' in fields:
        print('Unavailable: remove inline key and use token_var')
        return
    for field in ('url', 'token_var', 'haiku_model', 'sonnet_model', 'opus_model', 'fable_model'):
        print(f'{field}: {fields.get(field, "")}')


def main() -> None:
    action, filename, *args = sys.argv[1:]
    path = Path(filename)
    if action in ('help', '-h', '--help'):
        print('claude-provider [list|show NAME|edit|help]')
        print('Edit uses VISUAL or EDITOR (default vi); GUI editors must use a wait flag.')
        print('Requires Python 3.11+. Store credentials in environment variables, referenced by token_var.')
        return
    if action == 'run':
        run(path, args)
        return
    if action == 'edit':
        edit(path)
        return
    providers = load(path)
    if action == 'validate' and len(args) == 1:
        validate_selected(providers[args[0]])
    elif action == 'load':
        records(providers)
    elif action in ('list', 'ls'):
        for name, fields in sorted(providers.items()):
            show(name, fields)
    elif action in ('show', 'info') and len(args) == 1:
        show(args[0], providers[args[0]])
    else:
        raise ValueError('Use claude-provider help for supported commands')


if __name__ == '__main__':
    try:
        main()
    except (tomllib.TOMLDecodeError, KeyError, OSError, subprocess.CalledProcessError) as error:
        print(f'Provider operation failed: {type(error).__name__}', file=sys.stderr)
        sys.exit(1)
    except ValueError as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
