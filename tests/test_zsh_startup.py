from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
RC = ROOT / "dot_config/zsh/rc.d"


class StartupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.env = {"HOME": str(self.home), "PATH": "/usr/bin:/bin", "TERM": "dumb"}

    def shell(self, code):
        return subprocess.run(["/bin/zsh", "-f", "-c", code], env=self.env,
                              text=True, capture_output=True)

    def test_full_interactive_startup(self):
        config = self.home / ".config/zsh"
        config.mkdir(parents=True)
        (config / "rc.d").symlink_to(RC, target_is_directory=True)
        result = subprocess.run(["/bin/zsh", "-f", "-i", "-c", f'source {ROOT}/dot_zshenv; source {ROOT}/dot_zshrc'],
                                env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")
        self.assertEqual(result.stderr, "")

    def test_provider_runtime_is_declared(self):
        self.assertIn('brew "python"', (ROOT / "Brewfile").read_text())

    def test_repository_files_are_not_deployed(self):
        ignored = (ROOT / ".chezmoiignore").read_text().splitlines()
        self.assertIn("tests", ignored)
        self.assertIn(".memory", ignored)

    def test_optional_plugins(self):
        result = self.shell(f'source {RC}/00-init.zsh; source {RC}/90-plugins.zsh')
        self.assertEqual(result.stderr, "")
        self.assertEqual(result.returncode, 0)

    def test_completion_prefix(self):
        self.env["HOMEBREW_PREFIX"] = str(self.home / "brew")
        result = self.shell(f'source {RC}/00-init.zsh; source {RC}/05-compinit.zsh; print -l -- $fpath')
        self.assertEqual(result.stderr, "")
        self.assertIn(str(self.home / "brew/share/zsh-completions"), result.stdout.splitlines())
        self.assertEqual(result.stdout.splitlines()[0], str(self.home / ".config/zsh/completions"))

    def test_bun_completion_loads_after_compinit(self):
        completion = self.home / ".bun/_bun"
        completion.parent.mkdir()
        completion.write_text('_bun() { :; }\ncompdef _bun bun\n')
        result = self.shell(f'source {RC}/00-init.zsh; source {RC}/05-compinit.zsh; print -r -- "${{_comps[bun]-}}"')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertEqual(result.stdout, "_bun\n")

    def test_missing_or_empty_bun_completion_is_optional(self):
        completion = self.home / ".bun/_bun"
        completion.parent.mkdir()
        for present in (False, True):
            if present:
                completion.touch()
            with self.subTest(present=present):
                result = self.shell(f'source {RC}/00-init.zsh; source {RC}/05-compinit.zsh')
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, "")
                self.assertEqual(result.stderr, "")

    def test_ai_flags_are_opt_in(self):
        for name, flag in [("codex", "--dangerously-bypass-approvals-and-sandbox"),
                           ("gemini", "--yolo"), ("qwen", "--yolo")]:
            executable = self.home / name
            executable.write_text('#!/bin/sh\nprintf "%s\\n" "$@"\n')
            executable.chmod(0o700)
            self.env["PATH"] = f"{self.home}:/usr/bin:/bin"
            with self.subTest(command=name):
                normal = self.shell(f'source {RC}/11-ai-others.zsh; {name} --version')
                self.assertEqual(normal.stdout, "--version\n")
                unsafe = self.shell(f'source {RC}/11-ai-others.zsh; {name} --yolo task')
                self.assertEqual(unsafe.stdout, f"{flag}\ntask\n")

    def test_local_override_is_last(self):
        for relative in [".local/bin/env", ".config/event-sync/env.sh", ".zshrc.local"]:
            file = self.home / relative
            file.parent.mkdir(parents=True, exist_ok=True)
            file.write_text(f'ORDER="${{ORDER}}:{relative}"\n')
        result = self.shell(f'source {ROOT}/dot_zshrc; print -r -- "$ORDER"')
        self.assertEqual(result.stdout.strip().split(":")[-1], ".zshrc.local")

    def test_editor_consistency(self):
        result = self.shell(f'source {ROOT}/dot_zshenv; before=$EDITOR; source {RC}/20-settings.zsh; [[ $before == $EDITOR ]]')
        self.assertEqual(result.returncode, 0)

    def test_inherited_editor_is_preserved(self):
        self.env["EDITOR"] = "custom-editor --wait"
        result = self.shell(f'source {ROOT}/dot_zshenv; source {RC}/20-settings.zsh; print -r -- "$EDITOR"')
        self.assertEqual(result.stdout, "custom-editor --wait\n")

    def test_tips_are_opt_in(self):
        result = subprocess.run(["/bin/zsh", "-f", "-i", "-c", f'source {RC}/95-tips.zsh'],
                                env=self.env, text=True, capture_output=True)
        self.assertEqual(result.stdout, "")

    def test_secret_editor_accepts_arguments(self):
        executable = self.home / "test editor"
        executable.write_text('#!/bin/sh\nprintf "%s\\n" "$@"\n')
        executable.chmod(0o700)
        self.env["EDITOR"] = f'"{executable}" --wait'
        result = self.shell(f'source {RC}/30-aliases.zsh; eval esecret')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.splitlines(), ["--wait", str(self.home / ".config/zsh/.secret")])

    def test_reload_replaces_shell(self):
        result = self.shell(f'source {RC}/30-aliases.zsh; alias reload 2>/dev/null; functions reload')
        self.assertIn("exec", result.stdout)
        self.assertIn("login", result.stdout)
        self.assertNotIn("source", result.stdout)


if __name__ == "__main__":
    unittest.main()
