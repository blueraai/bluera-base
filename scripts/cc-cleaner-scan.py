#!/usr/bin/env python3
"""Claude Code Cleaner - Scanner

Analyzes ~/.claude/ and ~/.claude.json for common startup issues.
Outputs JSON-formatted scan report.

Usage:
    python3 cc-cleaner-scan.py [--verbose] [--json]
"""

import argparse
import json
import os
import platform
import re
import sys
from dataclasses import dataclass, field, asdict
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Optional, Union

# Type aliases for structured data
EvidenceValue = Union[str, int, bool, List[str]]
EnvInfo = Dict[str, Union[str, bool]]
PathInfo = Dict[str, Union[str, List[str]]]
MetricsInfo = Dict[str, Dict[str, int]]


@dataclass
class Evidence:
    key: str
    value: EvidenceValue


@dataclass
class Finding:
    id: str
    title: str
    risk: str  # info, low, medium, high, critical
    evidence: List[Evidence]
    why_it_matters: str
    recommended_actions: List[str]
    references: List[str] = field(default_factory=list)


@dataclass
class RemediationAction:
    id: str
    title: str
    safety: str  # safe, caution, destructive
    affects: List[str]
    preview: List[str]
    notes: str = ""


@dataclass
class ScanReport:
    created_at: str
    env: EnvInfo
    paths: PathInfo
    metrics: MetricsInfo
    findings: List[Finding]
    actions: List[RemediationAction]


def format_size(bytes_val: int) -> str:
    """Format bytes as human-readable string."""
    if bytes_val >= 1073741824:
        return f"{bytes_val / 1073741824:.1f}GB"
    elif bytes_val >= 1048576:
        return f"{bytes_val / 1048576:.1f}MB"
    elif bytes_val >= 1024:
        return f"{bytes_val / 1024:.1f}KB"
    return f"{bytes_val}B"


def get_dir_size(path: Path) -> int:
    """Get total size of directory in bytes (cross-platform)."""
    if not path.exists():
        return 0
    total = 0
    try:
        for entry in path.rglob("*"):
            if entry.is_file():
                try:
                    total += entry.stat().st_size
                except (PermissionError, OSError):
                    pass
    except (PermissionError, OSError):
        pass
    return total


def get_file_count(path: Path) -> int:
    """Count files in directory."""
    if not path.exists():
        return 0
    count = 0
    try:
        for entry in path.rglob("*"):
            if entry.is_file():
                count += 1
    except (PermissionError, OSError):
        pass
    return count


def is_wsl() -> bool:
    """Detect if running on WSL."""
    if os.environ.get("WSL_DISTRO_NAME"):
        return True
    try:
        with open("/proc/version", "r") as f:
            return "microsoft" in f.read().lower()
    except (FileNotFoundError, PermissionError):
        return False


class ClaudeCodeScanner:
    """Main scanner class."""

    def __init__(self, verbose: bool = False):
        self.verbose = verbose
        self.home = Path.home()
        self.claude_dir = self._resolve_claude_dir()
        self.claude_json = self.home / ".claude.json"

    def _resolve_claude_dir(self) -> Path:
        """Resolve ~/.claude or $CLAUDE_CONFIG_DIR."""
        config_dir = os.environ.get("CLAUDE_CONFIG_DIR")
        if config_dir:
            return Path(config_dir)
        return self.home / ".claude"

    def _log(self, msg: str) -> None:
        """Log message if verbose mode."""
        if self.verbose:
            print(f"[scan] {msg}", file=sys.stderr)

    def collect_env(self) -> EnvInfo:
        """Collect environment information."""
        return {
            "os": platform.system(),
            "os_version": platform.release(),
            "is_wsl": is_wsl(),
            "config_dir": str(self.claude_dir),
            "home_dir": str(self.home),
        }

    def collect_paths(self) -> PathInfo:
        """Collect relevant paths."""
        paths = {
            "claude_dir": str(self.claude_dir),
            "claude_json": str(self.claude_json),
            "settings_json": str(self.claude_dir / "settings.json"),
            "debug_dir": str(self.claude_dir / "debug"),
            "plugin_cache_dirs": [],
            "projects_dir": str(self.claude_dir / "projects"),
        }

        # Add plugin cache paths
        global_cache = self.claude_dir / "plugins" / "cache"
        if global_cache.exists():
            paths["plugin_cache_dirs"].append(str(global_cache))

        return paths

    def collect_metrics(self) -> MetricsInfo:
        """Collect file sizes and counts."""
        self._log("Collecting metrics...")

        sizes = {}
        counts = {}

        # ~/.claude.json size
        if self.claude_json.exists():
            sizes["claude_json"] = self.claude_json.stat().st_size
        else:
            sizes["claude_json"] = 0

        # ~/.claude/ total size
        sizes["claude_dir"] = get_dir_size(self.claude_dir)

        # Plugin cache
        cache_dir = self.claude_dir / "plugins" / "cache"
        sizes["plugin_cache"] = get_dir_size(cache_dir)
        counts["plugin_cache_files"] = get_file_count(cache_dir)

        # Projects
        projects_dir = self.claude_dir / "projects"
        sizes["projects"] = get_dir_size(projects_dir)
        counts["project_files"] = get_file_count(projects_dir)

        # Debug logs
        debug_dir = self.claude_dir / "debug"
        sizes["debug"] = get_dir_size(debug_dir)
        counts["debug_files"] = get_file_count(debug_dir)

        # CLAUDE.md
        claude_md = self.claude_dir / "CLAUDE.md"
        if claude_md.exists():
            sizes["claude_md"] = claude_md.stat().st_size
        else:
            sizes["claude_md"] = 0

        return {"sizes": sizes, "counts": counts}

    def detect_claude_json_bloat(self, metrics: Dict) -> Optional[Finding]:
        """Detector: .claude.json size."""
        self._log("Checking .claude.json size...")

        size = metrics["sizes"].get("claude_json", 0)
        if size == 0:
            return None

        # Determine risk level
        if size > 100 * 1024 * 1024:  # 100MB
            risk = "critical"
        elif size > 20 * 1024 * 1024:  # 20MB
            risk = "high"
        elif size > 5 * 1024 * 1024:  # 5MB
            risk = "medium"
        else:
            return None

        # Try to count history entries (without printing values)
        history_count = 0
        try:
            with open(self.claude_json, "r") as f:
                data = json.load(f)
                if isinstance(data, dict):
                    # Count various history-like keys
                    for key in ["history", "conversations", "messages", "chats"]:
                        if key in data and isinstance(data[key], list):
                            history_count += len(data[key])
        except (json.JSONDecodeError, PermissionError, OSError):
            pass

        evidence = [
            Evidence("size_bytes", size),
            Evidence("size_human", format_size(size)),
        ]
        if history_count > 0:
            evidence.append(Evidence("history_entries", history_count))

        return Finding(
            id="CLAUDE_JSON_BLOAT",
            title=f"~/.claude.json = {format_size(size)} (likely history accumulation)",
            risk=risk,
            evidence=evidence,
            why_it_matters="Large .claude.json causes slow startup and poor performance",
            recommended_actions=["RESET_CLAUDE_JSON"],
            references=["#5024", "#5653", "#1449", "#6394"],
        )

    def detect_plugin_cache(self, metrics: Dict) -> Optional[Finding]:
        """Detector: plugin cache regression."""
        self._log("Checking plugin cache...")

        size = metrics["sizes"].get("plugin_cache", 0)
        count = metrics["counts"].get("plugin_cache_files", 0)

        if count == 0:
            return None

        # Cache presence is potentially problematic (known regression)
        risk = "medium"
        if size > 50 * 1024 * 1024:  # 50MB
            risk = "high"

        return Finding(
            id="PLUGIN_CACHE_REGRESSION",
            title=f"~/.claude/plugins/cache = {format_size(size)}, {count} files",
            risk=risk,
            evidence=[
                Evidence("size_bytes", size),
                Evidence("size_human", format_size(size)),
                Evidence("file_count", count),
            ],
            why_it_matters="Plugin cache can cause inverted performance (slower with cache than without)",
            recommended_actions=["CLEAR_PLUGIN_CACHE"],
            references=["#15090"],
        )

    def detect_grove_timeout(self) -> Optional[Finding]:
        """Detector: Grove notice config timeout in debug logs."""
        self._log("Checking debug logs for Grove timeout...")

        debug_latest = self.claude_dir / "debug" / "latest"
        if not debug_latest.exists():
            return None

        patterns = [
            r"Grove notice config",
            r"timeout.*grove",
            r"SLOW OPERATION DETECTED",
        ]

        matches = []
        try:
            # Read only first 100KB of log
            with open(debug_latest, "r", errors="ignore") as f:
                content = f.read(100 * 1024)
                for pattern in patterns:
                    if re.search(pattern, content, re.IGNORECASE):
                        matches.append(pattern)
        except (PermissionError, OSError):
            return None

        if not matches:
            return None

        return Finding(
            id="GROVE_TIMEOUT",
            title="Debug log shows Grove notice config timeout",
            risk="high",
            evidence=[
                Evidence("patterns_matched", matches),
                Evidence("log_file", str(debug_latest)),
            ],
            why_it_matters="Startup blocks on failing/slow network fetch, adding 10-12s delay",
            recommended_actions=["DISABLE_NONESSENTIAL_TRAFFIC"],
            references=["#11442"],
        )

    def detect_wsl_powershell(self) -> Optional[Finding]:
        """Detector: WSL2 repeated PowerShell calls."""
        self._log("Checking for WSL PowerShell issues...")

        if not is_wsl():
            return None

        debug_latest = self.claude_dir / "debug" / "latest"
        if not debug_latest.exists():
            return None

        powershell_count = 0
        try:
            with open(debug_latest, "r", errors="ignore") as f:
                content = f.read(100 * 1024)
                powershell_count = len(re.findall(
                    r"powershell\.exe.*USERPROFILE", content, re.IGNORECASE
                ))
        except (PermissionError, OSError):
            return None

        if powershell_count < 3:
            return None

        return Finding(
            id="WSL_POWERSHELL",
            title=f"WSL: {powershell_count} repeated PowerShell USERPROFILE calls",
            risk="high",
            evidence=[
                Evidence("call_count", powershell_count),
                Evidence("is_wsl", True),
            ],
            why_it_matters="Repeated PowerShell invocations can add ~60s to startup on WSL2",
            recommended_actions=["SHOW_WSL_WORKAROUNDS"],
            references=["#14352"],
        )

    def detect_projects_bloat(self, metrics: Dict) -> Optional[Finding]:
        """Detector: ~/.claude/projects storage bloat."""
        self._log("Checking projects directory size...")

        size = metrics["sizes"].get("projects", 0)
        count = metrics["counts"].get("project_files", 0)

        if size < 500 * 1024 * 1024:  # 500MB threshold
            return None

        risk = "medium"
        if size > 1024 * 1024 * 1024:  # 1GB
            risk = "high"

        return Finding(
            id="PROJECTS_BLOAT",
            title=f"~/.claude/projects = {format_size(size)} across {count} files",
            risk=risk,
            evidence=[
                Evidence("size_bytes", size),
                Evidence("size_human", format_size(size)),
                Evidence("file_count", count),
            ],
            why_it_matters="Large session files may contribute to extension OOM or performance degradation",
            recommended_actions=["SET_CLEANUP_PERIOD", "PRUNE_SESSIONS"],
            references=["#8722"],
        )

    def detect_oversized_memory(self, metrics: Dict) -> Optional[Finding]:
        """Detector: Large CLAUDE.md or rules files."""
        self._log("Checking memory file sizes...")

        size = metrics["sizes"].get("claude_md", 0)

        if size < 100 * 1024:  # 100KB threshold
            return None

        return Finding(
            id="OVERSIZED_MEMORY",
            title=f"~/.claude/CLAUDE.md = {format_size(size)}",
            risk="low",
            evidence=[
                Evidence("size_bytes", size),
                Evidence("size_human", format_size(size)),
            ],
            why_it_matters="Large memory files increase context loading work at session start",
            recommended_actions=["SUGGEST_TRIM_MEMORY"],
            references=[],
        )

    def generate_actions(self, findings: List[Finding]) -> List[RemediationAction]:
        """Generate action list from findings."""
        action_ids = set()
        for finding in findings:
            action_ids.update(finding.recommended_actions)

        actions = []

        if "RESET_CLAUDE_JSON" in action_ids:
            actions.append(RemediationAction(
                id="RESET_CLAUDE_JSON",
                title="Backup & reset ~/.claude.json",
                safety="destructive",
                affects=["preferences", "auth", "history"],
                preview=["cp -p ~/.claude.json ~/.claude.json.bak.TS",
                        "mv ~/.claude.json ~/.claude.json.disabled.TS"],
                notes="Requires re-authentication after reset",
            ))

        if "CLEAR_PLUGIN_CACHE" in action_ids:
            actions.append(RemediationAction(
                id="CLEAR_PLUGIN_CACHE",
                title="Clear plugin cache",
                safety="safe",
                affects=["plugin_cache"],
                preview=["rm -rf ~/.claude/plugins/cache/*"],
                notes="Cache regenerates on next startup",
            ))

        if "DISABLE_NONESSENTIAL_TRAFFIC" in action_ids:
            actions.append(RemediationAction(
                id="DISABLE_NONESSENTIAL_TRAFFIC",
                title="Disable non-essential network traffic",
                safety="caution",
                affects=["telemetry", "bug_reporting", "notices"],
                preview=["Edit ~/.claude/settings.json: env.CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1"],
                notes="May affect telemetry and bug reporting",
            ))

        if "SET_CLEANUP_PERIOD" in action_ids:
            actions.append(RemediationAction(
                id="SET_CLEANUP_PERIOD",
                title="Set session cleanup period (auto-delete old sessions)",
                safety="safe",
                affects=["old_sessions"],
                preview=["Edit ~/.claude/settings.json: cleanupPeriodDays=14"],
                notes="Sessions inactive longer than N days deleted at startup",
            ))

        if "PRUNE_SESSIONS" in action_ids:
            actions.append(RemediationAction(
                id="PRUNE_SESSIONS",
                title="Prune old session files (>30 days)",
                safety="destructive",
                affects=["session_data"],
                preview=["tar backup + find ~/.claude/projects -mtime +30 -delete"],
                notes="Creates backup before pruning",
            ))

        if "PRUNE_DEBUG_LOGS" in action_ids:
            actions.append(RemediationAction(
                id="PRUNE_DEBUG_LOGS",
                title="Delete old debug logs (>14 days)",
                safety="safe",
                affects=["debug_logs"],
                preview=["find ~/.claude/debug -mtime +14 -delete"],
                notes="Debug logs are not critical",
            ))

        if "SHOW_WSL_WORKAROUNDS" in action_ids:
            actions.append(RemediationAction(
                id="SHOW_WSL_WORKAROUNDS",
                title="Show WSL2 workarounds",
                safety="safe",
                affects=[],
                preview=["Display known workarounds for WSL2 performance issues"],
                notes="Informational only - no automatic fix",
            ))

        if "SUGGEST_TRIM_MEMORY" in action_ids:
            actions.append(RemediationAction(
                id="SUGGEST_TRIM_MEMORY",
                title="Suggest trimming memory files",
                safety="safe",
                affects=[],
                preview=["Review ~/.claude/CLAUDE.md size and content"],
                notes="Informational - user decides what to trim",
            ))

        return actions

    def scan(self) -> ScanReport:
        """Run all detectors and generate report."""
        self._log("Starting scan...")

        metrics = self.collect_metrics()
        findings = []

        # Run each detector
        detectors = [
            lambda: self.detect_claude_json_bloat(metrics),
            lambda: self.detect_plugin_cache(metrics),
            self.detect_grove_timeout,
            self.detect_wsl_powershell,
            lambda: self.detect_projects_bloat(metrics),
            lambda: self.detect_oversized_memory(metrics),
        ]

        for detector in detectors:
            finding = detector()
            if finding:
                findings.append(finding)
                self._log(f"Found: {finding.id} ({finding.risk})")

        # Sort by risk (critical first)
        risk_order = {"critical": 0, "high": 1, "medium": 2, "low": 3, "info": 4}
        findings.sort(key=lambda f: risk_order.get(f.risk, 5))

        # Generate actions
        actions = self.generate_actions(findings)

        self._log(f"Scan complete: {len(findings)} findings, {len(actions)} actions")

        return ScanReport(
            created_at=datetime.now().isoformat(),
            env=self.collect_env(),
            paths=self.collect_paths(),
            metrics=metrics,
            findings=findings,
            actions=actions,
        )


def to_dict(obj: object) -> object:
    """Convert dataclass to dict recursively."""
    if hasattr(obj, "__dataclass_fields__"):
        return {k: to_dict(v) for k, v in asdict(obj).items()}  # type: ignore[arg-type]
    elif isinstance(obj, list):
        return [to_dict(item) for item in obj]
    elif isinstance(obj, dict):
        return {k: to_dict(v) for k, v in obj.items()}
    return obj


def main():
    parser = argparse.ArgumentParser(
        description="Scan ~/.claude for common startup issues"
    )
    parser.add_argument("--verbose", "-v", action="store_true",
                        help="Enable verbose output")
    parser.add_argument("--json", action="store_true",
                        help="Output raw JSON (default: formatted)")
    args = parser.parse_args()

    scanner = ClaudeCodeScanner(verbose=args.verbose)
    report = scanner.scan()

    # Convert to dict for JSON output
    report_dict = to_dict(report)

    if args.json:
        print(json.dumps(report_dict, indent=2))
    else:
        # Formatted output
        print(f"\n{'='*60}")
        print("Claude Code Cleaner - Scan Report")
        print(f"{'='*60}\n")

        # Summary
        sizes = report.metrics["sizes"]
        print(f"Total ~/.claude size: {format_size(sizes.get('claude_dir', 0))}")
        print(f"~/.claude.json size:  {format_size(sizes.get('claude_json', 0))}")
        print()

        # Findings
        if report.findings:
            print("Findings:")
            print("-" * 40)
            for finding in report.findings:
                risk_label = f"[{finding.risk.upper()}]".ljust(10)
                print(f"  {risk_label} {finding.title}")
            print()

            # Actions
            print("Recommended Actions:")
            print("-" * 40)
            for action in report.actions:
                safety_label = f"[{action.safety.upper()}]".ljust(14)
                print(f"  {safety_label} {action.title}")
                if action.notes:
                    print(f"                 {action.notes}")
            print()
        else:
            print("No issues found. Your Claude Code installation looks healthy!")
            print()

        print(f"Run with --json for machine-readable output")
        print()


if __name__ == "__main__":
    main()
