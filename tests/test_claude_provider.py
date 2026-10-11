import importlib.util
import contextlib
import io
import shlex
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
import unittest.mock

ROOT = Path(__file__).resolve().parents[1]
TOOL = ROOT / 'dot_config/zsh/executable_claude-provider.py'
spec = importlib.util.spec_from_file_location('provider', TOOL)
provider = importlib.util.module_from_spec(spec)
spec.loader.exec_module(provider)


class ProviderTests(unittest.TestCase):
    def test_expansion_is_data(self):
        with unittest.mock.patch.dict(os.environ, {'PROVIDER_TEST_HOST': 'example.invalid'}):
            self.assertEqual(provider.expand('${PROVIDER_TEST_HOST}/$(echo unsafe)/`id`'),
                             'example.invalid/$(echo unsafe)/`id`')

    def test_editor_preserves_comments_and_private_mode(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'providers.toml'
            text = '# Keep this comment\n[provider."quoted-name"]\nurl = "https://example.invalid"\ntoken_var = "TOKEN"\n'
            path.write_text(text)
            output = io.StringIO()
            with unittest.mock.patch.dict(os.environ, {'VISUAL': 'true'}), contextlib.redirect_stdout(output):
                provider.edit(path)
            self.assertIn('Only the target file changed', output.getvalue())
            self.assertIn('chezmoi add ' + shlex.quote(str(path)), output.getvalue())
            self.assertEqual(path.read_text(), text)
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)

    def test_inline_key_edit_rejected_and_display_redacted(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'providers.toml'
            original = '[provider.test]\nkey = "private-value"\n'
            path.write_text(original)
            with unittest.mock.patch.dict(os.environ, {'VISUAL': 'true'}):
                with self.assertRaisesRegex(ValueError, 'token_var'):
                    provider.edit(path)
            self.assertEqual(path.read_text(), original)
            result = subprocess.run(['python3', str(TOOL), 'show', str(path), 'test'],
                                    capture_output=True, text=True, check=True)
            self.assertNotIn('private-value', result.stdout + result.stderr)
            self.assertIn('token_var', result.stdout)
            self.assertEqual(list(Path(directory).iterdir()), [path])

    def test_invalid_edit_leaves_original_unchanged(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'providers.toml'
            original = '[provider.test]\nurl = "https://example.invalid"\n'
            path.write_text(original)

            def corrupt_editor(args, **kwargs):
                Path(args[-1]).write_text('invalid = "')

            with unittest.mock.patch('subprocess.run', side_effect=corrupt_editor):
                with self.assertRaises(ValueError):
                    provider.edit(path)
            self.assertEqual(path.read_text(), original)

    def test_semantically_invalid_edits_preserve_original(self):
        changes = ['url = "https://${HOST}:bad"',
                   'url = "https://user:password@${HOST}"',
                   'url = "ftp://example.invalid"', 'url = "https://host:bad"',
                   'url = "https://user:password@host"',
                   'url = "https://host"\nextra_flags = "ANTHROPIC_AUTH_TOKEN=bad"',
                   'url = "https://host"\nextra_flags = "CLAUDE_CODE_EFFORT_LEVEL=\'"']
        for change in changes:
            with self.subTest(change=change), tempfile.TemporaryDirectory() as directory:
                path = Path(directory) / 'providers.toml'
                original = '# original\n[provider.test]\nurl = "https://example.invalid"\n'
                path.write_text(original)
                def editor(args, **kwargs):
                    Path(args[-1]).write_text('[provider.test]\ntoken_var = "TOKEN"\n' + change + '\n')
                with unittest.mock.patch('subprocess.run', side_effect=editor):
                    with self.assertRaises(ValueError):
                        provider.edit(path)
                self.assertEqual(path.read_text(), original)
                self.assertEqual(list(Path(directory).iterdir()), [path])

    def test_edit_requires_token_variable_name_not_secret(self):
        for field in ('', 'token_var = ""\n'):
            with self.subTest(field=field), tempfile.TemporaryDirectory() as directory:
                path = Path(directory) / 'providers.toml'
                original = '[provider.test]\nurl = "https://host"\ntoken_var = "TOKEN"\n'
                path.write_text(original)
                def editor(args, **kwargs):
                    Path(args[-1]).write_text('[provider.test]\nurl = "https://host"\n' + field)
                with unittest.mock.patch('subprocess.run', side_effect=editor):
                    with self.assertRaisesRegex(ValueError, 'token_var'):
                        provider.edit(path)
                self.assertEqual(path.read_text(), original)

    def test_assignment_expansion_preserves_values(self):
        for flags in ('CLAUDE_CODE_EFFORT_LEVEL=$EFFORT', ['CLAUDE_CODE_EFFORT_LEVEL=$EFFORT']):
            fields = dict(url='https://host', token_var='TOKEN', extra_flags=flags)
            with unittest.mock.patch.dict(os.environ, {'TOKEN': 'secret', 'EFFORT': 'high "effort" $(no)'}, clear=True):
                self.assertEqual(provider.environment(fields)['CLAUDE_CODE_EFFORT_LEVEL'], 'high "effort" $(no)')

    def test_static_url_templates_do_not_need_environment(self):
        for url in ('${ENDPOINT}/v1', '${SCHEME}://${HOST}:${PORT}/v1', 'https://${HOST}/v1'):
            with unittest.mock.patch.dict(os.environ, {}, clear=True):
                provider.validate_static({'url': url, 'token_var': 'TOKEN'})
                with self.assertRaises(ValueError):
                    provider.validate_selected({'url': url, 'token_var': 'TOKEN'})

    def test_edit_templates_without_environment(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'providers.toml'
            original = '[provider.test]\nurl = "${ENDPOINT}"\ntoken_var = "TOKEN"\nextra_flags = "CLAUDE_CODE_EFFORT_LEVEL=$EFFORT"\n'
            path.write_text(original)
            with unittest.mock.patch.dict(os.environ, {'VISUAL': 'true'}, clear=True):
                provider.edit(path)
            self.assertEqual(path.read_text(), original)

    def test_invalid_token_reference_fails_closed(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'providers.toml'
            path.write_text('[provider.test]\ntoken_var = "BAD[$(echo unsafe)]"\n')
            with self.assertRaises(ValueError):
                provider.load(path)

    def test_missing_tomllib_has_concise_requirement(self):
        result = subprocess.run(['python3', '-c',
                                 'import runpy,sys; sys.modules["tomllib"] = None; runpy.run_path(sys.argv[1])',
                                 str(TOOL)], capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Python 3.11', result.stderr)
        self.assertNotIn('Traceback', result.stderr)

    def test_completion_uses_explicit_provider_option(self):
        text = (ROOT / 'dot_config/zsh/completions/_claude').read_text()
        self.assertIn('--provider[', text)
        self.assertNotIn('--${name}', text)

    def test_completion_has_no_global_mutation(self):
        for filename in ('_claude', '_claude-provider', '_cpf'):
            text = (ROOT / 'dot_config/zsh/completions' / filename).read_text()
            self.assertNotIn('typeset -ga', text)
            self.assertNotIn('_CLAUDE_PROVIDER_NAMES+=', text)


if __name__ == '__main__':
    unittest.main()
