import os
import pathlib
import pty
import select
import signal
import struct
import tempfile
import termios
import time
import unittest
import re
import unicodedata
import fcntl


ROOT = pathlib.Path(__file__).resolve().parents[2]
PICKER = ROOT / "codex-terminal" / "scripts" / "codex-task-picker.sh"


class PickerPtyTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.temp = pathlib.Path(self.tempdir.name)
        self.bin = self.temp / "bin"
        self.bin.mkdir()
        self.log = self.temp / "picker.log"
        self.context_marker = self.temp / "context-called"

        self._stub(
            "codex",
            """#!/bin/sh
if [ "$1" = "--version" ]; then
  echo "codex-cli 0.144.1"
  exit 0
fi
printf 'codex %s\n' "$*" >> "$PICKER_LOG"
""",
        )
        self._stub(
            "tmux",
            """#!/bin/sh
printf 'tmux %s\n' "$*" >> "$PICKER_LOG"
if [ "$1" = "has-session" ]; then
  [ "$TMUX_ACTIVE" = "1" ]
  exit
fi
exit 0
""",
        )
        self._stub(
            "ha-context",
            """#!/bin/sh
touch "$CONTEXT_MARKER"
exit 0
""",
        )
        self._stub("ha-safe-edit", "#!/bin/sh\nexit \"$CHECK_RESULT\"\n")
        self._stub("codex-ha", "#!/bin/sh\nexit 0\n")

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    def _stub(self, name: str, body: str) -> None:
        path = self.bin / name
        path.write_text(body, encoding="utf-8")
        path.chmod(0o755)

    def _spawn(
        self, *, active: bool = False, columns: int = 80, check_result: int = 0
    ) -> tuple[int, int]:
        pid, fd = pty.fork()
        if pid == 0:
            fcntl.ioctl(
                0,
                termios.TIOCSWINSZ,
                struct.pack("HHHH", 40, columns, 0, 0),
            )
            env = os.environ.copy()
            env.update(
                {
                    "PATH": f"{self.bin}:{env['PATH']}",
                    "HOME": str(self.temp),
                    "CODEX_HOME": str(self.temp / ".codex"),
                    "COLUMNS": str(columns),
                    "LINES": "40",
                    "TERM": "xterm-256color",
                    "PICKER_LOG": str(self.log),
                    "CONTEXT_MARKER": str(self.context_marker),
                    "TMUX_ACTIVE": "1" if active else "0",
                    "CHECK_RESULT": str(check_result),
                    "CODEX_HA_MCP_MODE": "ha-mcp",
                }
            )
            os.execve("/bin/bash", ["/bin/bash", str(PICKER)], env)
        return pid, fd

    def _read_until(self, fd: int, expected: bytes, timeout: float = 3.0) -> bytes:
        output = bytearray()
        deadline = time.monotonic() + timeout
        while expected not in output and time.monotonic() < deadline:
            readable, _, _ = select.select([fd], [], [], 0.05)
            if not readable:
                continue
            try:
                output.extend(os.read(fd, 65536))
            except OSError:
                break
        self.assertIn(expected, output)
        return bytes(output)

    def _wait_for_exit(self, pid: int, fd: int, timeout: float = 2.0) -> int:
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            result, status = os.waitpid(pid, os.WNOHANG)
            if result:
                os.close(fd)
                return os.waitstatus_to_exitcode(status)
            readable, _, _ = select.select([fd], [], [], 0.02)
            if readable:
                try:
                    os.read(fd, 65536)
                except OSError:
                    pass
        self.fail("Procesul meniului nu s-a închis la timp")

    def _finish(self, pid: int, fd: int) -> None:
        try:
            os.write(fd, b"q")
        except OSError:
            pass
        deadline = time.monotonic() + 2
        while time.monotonic() < deadline:
            result, _ = os.waitpid(pid, os.WNOHANG)
            if result:
                os.close(fd)
                break
            readable, _, _ = select.select([fd], [], [], 0.02)
            if readable:
                try:
                    os.read(fd, 65536)
                except OSError:
                    pass
        else:
            os.close(fd)
            try:
                os.killpg(pid, 9)
            except ProcessLookupError:
                pass
            deadline = time.monotonic() + 1
            while time.monotonic() < deadline:
                result, _ = os.waitpid(pid, os.WNOHANG)
                if result:
                    break
                time.sleep(0.01)

    def test_navigation_wraps_without_full_redraw_or_context_refresh(self) -> None:
        pid, fd = self._spawn()
        initial = self._read_until(fd, b"Q / Esc")
        started = time.monotonic()
        os.write(fd, b"\x1b[A")
        changed = self._read_until(fd, "Instrumente".encode(), timeout=0.5)
        elapsed = time.monotonic() - started
        combined = initial + changed
        self.assertLess(elapsed, 0.05)
        self.assertEqual(combined.count(b"\x1b[H\x1b[J"), 1)
        self.assertFalse(self.context_marker.exists())
        self._finish(pid, fd)

    def test_resume_launches_saved_conversation(self) -> None:
        pid, fd = self._spawn()
        self._read_until(fd, b"Q / Esc")
        os.write(fd, b"2")
        self._read_until(fd, "Pornesc Codex".encode())
        self._finish(pid, fd)
        log = self.log.read_text(encoding="utf-8")
        self.assertIn("tmux kill-session -t codex", log)
        self.assertIn("tmux new-session -s codex", log)
        self.assertIn(" resume", log)

    def test_preset_launches_with_romanian_prompt(self) -> None:
        pid, fd = self._spawn()
        self._read_until(fd, b"Q / Esc")
        os.write(fd, b"3")
        self._read_until(fd, "Pornesc Codex".encode())
        self._finish(pid, fd)
        log = self.log.read_text(encoding="utf-8", errors="replace")
        self.assertIn("mai multe dispozitive", log)
        self.assertIn("ha-safe-edit", log)

    def test_new_conversation_replaces_active_session_immediately(self) -> None:
        pid, fd = self._spawn(active=True)
        self._read_until(fd, b"Q / Esc")
        os.write(fd, b"2")
        self._read_until(fd, "Pornesc Codex".encode())
        self._finish(pid, fd)
        log = self.log.read_text(encoding="utf-8")
        self.assertIn("tmux kill-session -t codex", log)
        self.assertIn("tmux new-session -s codex", log)

    def test_tools_submenu_opens_and_escape_returns(self) -> None:
        pid, fd = self._spawn()
        self._read_until(fd, b"Q / Esc")
        os.write(fd, b"7")
        self._read_until(fd, "Rulează diagnosticul complet".encode())
        os.write(fd, b"\x1b")
        self._read_until(fd, "Alege ce vrei să faci".encode())
        self.assertFalse(self.context_marker.exists())
        self._finish(pid, fd)

    def test_resize_recomputes_the_layout(self) -> None:
        pid, fd = self._spawn(columns=92)
        self._read_until(fd, b"Q / Esc")
        fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", 40, 52, 0, 0))
        os.kill(pid, signal.SIGWINCH)
        resized = self._read_until(fd, "mută".encode())
        self.assertIn(b"\x1b[H\x1b[J", resized)
        self._finish(pid, fd)

    def test_narrow_standard_and_wide_layouts_do_not_wrap(self) -> None:
        ansi = re.compile(r"\x1b\[[0-9;?]*[A-Za-z]")

        def width(value: str) -> int:
            return sum(
                0
                if unicodedata.combining(char)
                else 2
                if unicodedata.east_asian_width(char) in {"F", "W"}
                else 1
                for char in value
            )

        for columns in (52, 92, 120):
            with self.subTest(columns=columns):
                pid, fd = self._spawn(columns=columns)
                marker = b"Q / Esc" if columns >= 66 else b"Q"
                output = self._read_until(fd, marker)
                plain = ansi.sub("", output.decode("utf-8", errors="replace"))
                self.assertLessEqual(max(width(line) for line in plain.splitlines()), columns)
                self._finish(pid, fd)

    def test_tool_failure_returns_a_clear_message_and_keeps_menu_available(self) -> None:
        pid, fd = self._spawn(check_result=9)
        self._read_until(fd, b"Q / Esc")
        os.write(fd, b"7")
        self._read_until(fd, "Verifică fișierele Home Assistant".encode())
        os.write(fd, b"2")
        self._read_until(fd, b"cod 9")
        os.write(fd, b"x")
        self._read_until(fd, "Rulează diagnosticul complet".encode())
        self._finish(pid, fd)

    def test_tool_success_returns_a_clear_message(self) -> None:
        pid, fd = self._spawn()
        self._read_until(fd, b"Q / Esc")
        os.write(fd, b"7")
        self._read_until(fd, "Actualizează datele".encode())
        os.write(fd, b"1")
        self._read_until(fd, "s-a încheiat cu succes".encode())
        self.assertTrue(self.context_marker.exists())
        os.write(fd, b"x")
        self._read_until(fd, "Rulează diagnosticul complet".encode())
        self._finish(pid, fd)

    def test_quit_exits_cleanly(self) -> None:
        pid, fd = self._spawn()
        self._read_until(fd, b"Q / Esc")
        os.write(fd, b"q")
        self.assertEqual(self._wait_for_exit(pid, fd), 0)


if __name__ == "__main__":
    unittest.main()
