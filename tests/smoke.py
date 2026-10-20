"""Exercise the real image offline, without a WhatsApp account."""

import json
import subprocess
import sys
import time
import uuid
from pathlib import Path

image = sys.argv[1]
version = next(
    line.split("=", 1)[1].removeprefix("v")
    for line in (Path(__file__).resolve().parents[1] / "Dockerfile").read_text().splitlines()
    if line.startswith("ARG WACLI_VERSION=")
)
prefix = "wacli-smoke-" + uuid.uuid4().hex[:12]
volume = prefix + "-data"
containers = []


def docker(*args, check=True):
    return subprocess.run(
        ["docker", *args], check=check, capture_output=True, text=True, timeout=60
    )


def start(suffix):
    name = prefix + "-" + suffix
    docker(
        "run",
        "-d",
        "--rm",
        "--network",
        "none",
        "--name",
        name,
        "-v",
        volume + ":/data",
        image,
    )
    containers.append(name)
    for _ in range(100):
        if "Ready. Run wacli-pair" in docker("logs", name).stdout:
            return name
        time.sleep(0.2)
    raise AssertionError("Worker did not become ready: " + docker("logs", name).stderr)


try:
    docker("volume", "create", volume)
    name = start("first")
    assert docker("exec", name, "wacli", "--version").stdout.strip() == "wacli " + version
    status = json.loads(
        docker("exec", name, "wacli-run", "--json", "auth", "status").stdout
    )
    assert status["success"] and status["data"]["authenticated"] is False
    # This exercises the linked SQLite/FTS build rather than only --help.
    search = json.loads(
        docker(
            "exec", name, "wacli-run", "--json", "messages", "search", "offline-smoke"
        ).stdout
    )
    assert search["success"] is True
    assert (
        docker("exec", name, "stat", "-c", "%a:%u", "/data/store").stdout.strip()
        == "700:10001"
    )
    assert (
        docker(
            "exec", name, "stat", "-c", "%a:%u", "/data/store/session.db"
        ).stdout.strip()
        == "600:10001"
    )
    worker_uid = docker(
        "exec",
        name,
        "sh",
        "-c",
        'set -- $(cat /proc/1/task/1/children); stat -c %u /proc/"$1"',
    ).stdout
    assert worker_uid.strip() == "10001"
    assert docker("exec", name, "wacli-pair", "--help").returncode == 0
    docker(
        "exec",
        name,
        "gosu",
        "wacli",
        "sh",
        "-c",
        "printf persisted > /data/store/persistence.txt",
    )
    docker("stop", "--time", "5", name)
    containers.remove(name)

    name = start("second")
    assert (
        docker("exec", name, "cat", "/data/store/persistence.txt").stdout == "persisted"
    )
    status = json.loads(
        docker("exec", name, "wacli-run", "--json", "auth", "status").stdout
    )
    assert status["data"]["authenticated"] is False
    print("Offline startup, SQLite search, session permissions and persistence passed.")
finally:
    for name in containers:
        docker("stop", "--time", "5", name, check=False)
    docker("volume", "rm", volume, check=False)
