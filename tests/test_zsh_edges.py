from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
RC = ROOT / "dot_config/zsh/rc.d"


class ShortcutTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name) / "home with ' quote"
        self.home.mkdir()
        self.env = {"HOME": str(self.home), "PATH": "/usr/bin:/bin", "TERM": "dumb"}

    def shell(self, code):
        return subprocess.run(["/bin/zsh", "-f", "-c", code], env=self.env,
                              text=True, capture_output=True)

    def test_clipboard_widget_preserves_failure(self):
        result = self.shell(f'''
            zle() {{ if [[ "$1" == -M ]]; then print -r -- "$2"; fi; }}
            source {RC}/80-keybindings.zsh
            pbcopy() {{ return 19; }}
            BUFFER=example
            _copybuffer
        ''')
        self.assertEqual(result.returncode, 19, result.stderr)
        self.assertEqual(result.stdout, "")

    def test_clipboard_widget_reports_success(self):
        result = self.shell(f'''
            zle() {{ if [[ "$1" == -M ]]; then print -r -- "$2"; fi; }}
            source {RC}/80-keybindings.zsh
            pbcopy() {{ command cat >/dev/null; }}
            BUFFER=example
            _copybuffer
        ''')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "已复制到剪贴板\n")

    def test_directory_aliases_quote_home(self):
        for shortcut, directory in [("down", "Downloads"), ("dev", "Developer"), ("doc", "Documents")]:
            with self.subTest(shortcut=shortcut):
                result = self.shell(f'''
                    source {RC}/30-aliases.zsh
                    cd() {{ print -rl -- "$@"; }}
                    eval {shortcut}
                ''')
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout.splitlines(), [str(self.home / directory)])

    def test_brew_alias_quotes_home(self):
        result = self.shell(f'''
            source {RC}/30-aliases.zsh
            brew() {{ print -rl -- "$@"; }}
            eval brewst
        ''')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.splitlines(), ["bundle", f"--file={self.home}/.local/share/chezmoi/Brewfile"])


if __name__ == "__main__":
    unittest.main()
