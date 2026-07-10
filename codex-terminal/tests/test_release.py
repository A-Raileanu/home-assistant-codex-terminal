import pathlib
import re
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[2]
ADDON = ROOT / "codex-terminal"


class ReleaseConsistencyTests(unittest.TestCase):
    def test_version_pins(self) -> None:
        dockerfile = (ADDON / "Dockerfile").read_text(encoding="utf-8")
        config = (ADDON / "config.yaml").read_text(encoding="utf-8")
        build = (ADDON / "build.yaml").read_text(encoding="utf-8")

        self.assertRegex(dockerfile, r"ARG CODEX_VERSION=0\.144\.1\b")
        self.assertRegex(dockerfile, r"ARG HA_MCP_VERSION=7\.12\.0\b")
        self.assertRegex(
            dockerfile,
            r"uv pip install\s+\\\s+--python /opt/ha-mcp/bin/python\s+\\\s+"
            r"--index-strategy unsafe-best-match",
        )
        self.assertTrue(re.search(r'^version: "1\.3\.0"$', config, re.MULTILINE))
        self.assertRegex(config, r'ha_mcp_version: "7\.12\.0"')
        self.assertEqual(build.count("-base-python:3.13-alpine3.22"), 3)

    def test_old_or_unclear_user_wording_is_gone(self) -> None:
        forbidden = (
            "0.142.3",
            "3.5.1",
            "din ce în ce",
            "task picker",
            "device-uri",
            "dashboard-uri",
            "trigger-e",
            "workflow",
            "Default-urile",
            " fără friction",
            "Usage:",
            "Unknown command:",
        )
        suffixes = {".md", ".sh", ".py", ".yaml", ".yml"}
        failures: list[str] = []
        for path in ROOT.rglob("*"):
            if not path.is_file() or path.suffix not in suffixes:
                continue
            if "tests" in path.parts or ".github" in path.parts or path.name == "CHANGELOG.md":
                continue
            text = path.read_text(encoding="utf-8", errors="replace")
            for phrase in forbidden:
                if phrase in text:
                    failures.append(f"{path.relative_to(ROOT)}: {phrase}")
        self.assertEqual(failures, [])

    def test_local_skill_links_point_to_existing_headings(self) -> None:
        skills = ADDON / "skills" / "home-assistant"

        def slug(heading: str) -> str:
            heading = heading.strip().lower()
            heading = re.sub(r"[`*_{}\[\]()]", "", heading)
            heading = re.sub(r"[^\w\- ]", "", heading)
            return re.sub(r" +", "-", heading)

        failures: list[str] = []
        link_pattern = re.compile(r"\[[^]]+\]\(([^)]+\.md)#([^)]+)\)")
        for source in skills.rglob("*.md"):
            for match in link_pattern.finditer(source.read_text(encoding="utf-8")):
                target = (source.parent / match.group(1)).resolve()
                if not target.exists():
                    failures.append(f"{source.name}: lipsește {match.group(1)}")
                    continue
                headings = {
                    slug(value)
                    for value in re.findall(
                        r"^#{1,6}\s+(.+)$", target.read_text(encoding="utf-8"), re.MULTILINE
                    )
                }
                if match.group(2) not in headings:
                    failures.append(f"{source.name}: lipsește #{match.group(2)}")
        self.assertEqual(failures, [])


if __name__ == "__main__":
    unittest.main()
