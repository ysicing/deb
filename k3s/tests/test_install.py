#!/usr/bin/env python3
"""在临时根目录验证维护脚本，禁止接触宿主机的服务和配置。"""

import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest


SOURCE = Path(__file__).resolve().parents[1]


class InstallTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.log = self.root / "systemctl.log"
        self.bin = self.root / "bin"
        self.bin.mkdir()
        mock = self.bin / "systemctl"
        mock.write_text(
            f"#!{sys.executable}\n"
            "import os, sys\n"
            "with open(os.environ['SYSTEMCTL_LOG'], 'a') as log:\n"
            "    log.write(' '.join(sys.argv[1:]) + '\\n')\n"
            "if sys.argv[1] == 'show':\n"
            "    print(os.environ.get('EXEC_START', ''))\n"
            "elif sys.argv[1] == 'list-unit-files':\n"
            "    print(os.environ.get('UNIT_FILES', ''))\n"
            "elif sys.argv[1] == 'list-units':\n"
            "    print(os.environ.get('LOADED_UNITS', ''))\n"
        )
        mock.chmod(0o755)
        self.env = dict(
            os.environ,
            PATH=f"{self.bin}:{os.environ['PATH']}",
            SYSTEMCTL_LOG=str(self.log),
            EXEC_START="",
            UNIT_FILES="",
            LOADED_UNITS="",
        )
        self.write("/usr/local/bin/k3s", b"new binary", mode=0o755)
        for role, command in (("master", "server"), ("worker", "agent")):
            template = (SOURCE / "k3s.service.tmpl").read_text()
            self.write(
                f"/usr/share/ys-k3s-{role}/k3s.service",
                template.replace("{{ .Command }}", command),
            )

    def path(self, path):
        return self.root / path.lstrip("/")

    def write(self, path, content, mode=0o644):
        target = self.path(path)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(content if isinstance(content, bytes) else self.sandbox(content).encode())
        target.chmod(mode)
        return target

    def sandbox(self, content):
        return re.sub(
            r"(?<![A-Za-z0-9_/])/(?:etc|usr|run|lib|var)(?=/)",
            lambda match: str(self.root) + match.group(),
            content,
        )

    def run_hook(self, hook="postinstall", role="master", argument="configure", ok=True):
        script = (SOURCE / "scripts" / f"{hook}.sh").read_text()
        script = script.replace("{{ .Role }}", role).replace(
            "{{ .Service }}", "k3s" if role == "master" else "k3s-agent"
        )
        script = self.sandbox(script)
        result = subprocess.run(
            ["sh", "-eu", "-c", script, hook, argument],
            env=self.env,
            capture_output=True,
            text=True,
        )
        if ok:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0)
        return result

    def assert_no_service_changes(self):
        calls = self.log.read_text() if self.log.exists() else ""
        self.assertNotRegex(calls, r"(?m)^(daemon-reload|start|restart|enable|stop|disable)")

    def test_fresh_master_and_worker_stay_stopped(self):
        for role, service, command in (
            ("master", "k3s", "server"),
            ("worker", "k3s-agent", "agent"),
        ):
            with self.subTest(role=role):
                self.run_hook(role=role)
                unit = self.path(f"/etc/systemd/system/{service}.service")
                self.assertIn(f"k3s {command}", unit.read_text())
                self.assertEqual(os.readlink(self.path("/usr/local/bin/kubectl")), "k3s")
                self.assertEqual(self.log.read_text(), (
                    "list-unit-files k3s*.service --no-legend --no-pager\n"
                    "list-units --all k3s*.service --plain --no-legend --no-pager\n"
                    "daemon-reload\n"
                ))
                self.run_hook("preremove", role, "remove")
                self.run_hook("postremove", role, "remove")
                self.assertFalse(unit.exists())
                self.assertFalse(self.path("/usr/local/bin/kubectl").is_symlink())
                self.log.unlink()

    def test_existing_stopped_service_preserves_all_configuration(self):
        unit = self.write(
            "/etc/systemd/system/k3s.service",
            "[Service]\nExecStart=/usr/local/bin/k3s server --disable traefik\n",
        )
        config = self.write("/etc/rancher/k3s/config.yaml", "cluster-init: true\n")
        environment = self.write("/etc/systemd/system/k3s.service.env", "K3S_TOKEN=keep\n")
        before = {p: (p.read_bytes(), p.stat().st_mtime_ns) for p in (unit, config, environment)}
        self.run_hook(role="worker")
        self.assert_no_service_changes()
        for path, expected in before.items():
            self.assertEqual((path.read_bytes(), path.stat().st_mtime_ns), expected)
        self.assertFalse(self.path("/etc/systemd/system/k3s-agent.service").exists())
        self.assertFalse(self.path("/usr/local/bin/kubectl").exists())
        self.assertFalse(self.path("/var/lib/ys-k3s").exists())

    def test_custom_running_binary_is_atomically_replaced(self):
        binary = self.write("/opt/k3s/bin/k3s", "old binary", mode=0o755)
        self.env["UNIT_FILES"] = "k3s-custom.service enabled enabled"
        self.env["EXEC_START"] = f"{{ path={binary} ; argv[]={binary} server ; }}"
        with binary.open("rb") as running:
            self.run_hook()
            self.assertEqual(running.read(), b"old binary")
        self.assertEqual(binary.read_bytes(), b"new binary")
        self.assertEqual(binary.stat().st_mode & 0o777, 0o755)
        self.assert_no_service_changes()

    def test_loaded_unit_without_file_is_detected(self):
        binary = self.write("/opt/k3s/bin/k3s", "old binary")
        self.env["LOADED_UNITS"] = "k3s-agent.service loaded active running K3s"
        self.env["EXEC_START"] = f"{{ path={binary} ; argv[]={binary} agent ; }}"
        self.run_hook()
        self.assertEqual(binary.read_bytes(), b"new binary")
        self.assert_no_service_changes()

    def test_custom_binary_symlink_is_preserved(self):
        binary = self.write("/opt/k3s/releases/current", "old binary")
        link = self.path("/opt/k3s/k3s")
        link.symlink_to(binary)
        self.env["UNIT_FILES"] = "k3s-custom.service enabled"
        self.env["EXEC_START"] = f"{{ path={link} ; argv[]={link} server ; }}"
        self.run_hook()
        self.assertTrue(link.is_symlink())
        self.assertEqual(os.readlink(link), str(binary))
        self.assertEqual(binary.read_bytes(), b"new binary")
        self.assert_no_service_changes()

    def test_dropin_uses_systemd_resolved_binary(self):
        binary = self.write("/opt/custom/k3s", "old binary")
        self.write("/usr/lib/systemd/system/k3s.service", "[Service]\nExecStart=/usr/local/bin/k3s server\n")
        override = self.write(
            "/etc/systemd/system/k3s.service.d/override.conf",
            f"[Service]\nExecStart=\nExecStart={binary} server\n",
        )
        before = override.read_bytes()
        self.env["EXEC_START"] = f"{{ path={binary} ; argv[]={binary} server ; }}"
        self.run_hook()
        self.assertEqual(binary.read_bytes(), b"new binary")
        self.assertEqual(override.read_bytes(), before)
        self.assert_no_service_changes()

    def test_multiple_services_update_each_binary(self):
        self.env["UNIT_FILES"] = "k3s-one.service disabled\nk3s-two.service disabled"
        binaries = []
        for name in ("one", "two"):
            binary = self.write(f"/usr/local/{name}/k3s", "old")
            binaries.append(binary)
            self.write(
                f"/etc/systemd/system/k3s-{name}.service",
                f"[Service]\nExecStart=/usr/local/{name}/k3s \\\n    server\n",
            )
        self.run_hook()
        for binary in binaries:
            self.assertEqual(binary.read_bytes(), b"new binary")
        self.assert_no_service_changes()

    def test_masked_service_is_preserved(self):
        unit = self.path("/etc/systemd/system/k3s.service")
        unit.parent.mkdir(parents=True)
        unit.symlink_to("/dev/null")
        self.run_hook()
        self.assertEqual(os.readlink(unit), "/dev/null")
        self.assert_no_service_changes()

    def test_unresolvable_service_fails_without_initializing(self):
        self.env["UNIT_FILES"] = "k3s-custom.service disabled"
        self.run_hook(ok=False)
        self.assertFalse(self.path("/etc/systemd/system/k3s.service").exists())
        self.assert_no_service_changes()

    def test_dropin_without_resolved_execstart_fails_safely(self):
        self.write("/etc/systemd/system/k3s.service", "[Service]\nExecStart=/usr/local/bin/k3s server\n")
        self.write("/etc/systemd/system/k3s.service.d/override.conf", "[Service]\nExecStart=/opt/k3s server\n")
        self.run_hook(ok=False)
        self.assert_no_service_changes()

    def test_upgrade_and_removal_leave_adopted_services_untouched(self):
        unit = self.write("/etc/systemd/system/k3s.service", "existing service")
        for argument in ("upgrade", "remove", "purge"):
            self.run_hook("preremove", argument=argument)
            self.run_hook("postremove", argument=argument)
        self.assertEqual(unit.read_text(), "existing service")
        self.assert_no_service_changes()

    def test_upgrade_leaves_package_created_unit_running(self):
        self.run_hook()
        self.log.unlink()
        self.run_hook()
        self.run_hook("preremove", argument="upgrade")
        self.run_hook("postremove", argument="upgrade")
        self.assert_no_service_changes()

    def test_removal_preserves_modified_unit_and_cluster_data(self):
        self.run_hook()
        unit = self.write("/etc/systemd/system/k3s.service", "user modified unit")
        data = self.write("/var/lib/rancher/k3s/server/db/state.db", "cluster data")
        config = self.write("/etc/rancher/k3s/config.yaml", "user config")
        self.log.unlink()
        self.run_hook("preremove", argument="remove")
        self.run_hook("postremove", argument="remove")
        self.assertEqual(unit.read_text(), "user modified unit")
        self.assertEqual(data.read_text(), "cluster data")
        self.assertEqual(config.read_text(), "user config")
        self.assert_no_service_changes()

    def test_existing_tools_are_preserved(self):
        tool = self.write("/usr/local/bin/kubectl", "existing kubectl")
        self.run_hook()
        self.run_hook("preremove", argument="remove")
        self.run_hook("postremove", argument="remove")
        self.assertEqual(tool.read_text(), "existing kubectl")


if __name__ == "__main__":
    unittest.main()
