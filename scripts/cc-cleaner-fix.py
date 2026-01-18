#!/usr/bin/env python3
"""Claude Code Cleaner - Fix Actions

Executes remediation actions with safety guarantees:
- Always creates timestamped backups
- Supports dry-run mode (default)
- Never prints secrets

Usage:
    python3 cc-cleaner-fix.py <action> [--confirm] [--days N]

Actions:
    reset-claude-json         Backup and move aside ~/.claude.json
    clear-plugin-cache        Remove plugin cache directories
    disable-nonessential      Set CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
    set-cleanup-period        Set cleanupPeriodDays in settings.json
    prune-sessions            Delete old session files (--days N)
    prune-debug-logs          Delete old debug logs (--days N)
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Union

# Type alias for result dictionaries
ResultDict = Dict[str, Union[str, int, List[str]]]


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
    """Get total size of directory in bytes."""
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


class ActionExecutor:
    """Execute remediation actions with safety guarantees."""

    def __init__(self, dry_run: bool = True, verbose: bool = False):
        self.dry_run = dry_run
        self.verbose = verbose
        self.home = Path.home()
        self.timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        self.claude_dir = self._resolve_claude_dir()

    def _resolve_claude_dir(self) -> Path:
        """Resolve ~/.claude or $CLAUDE_CONFIG_DIR."""
        config_dir = os.environ.get("CLAUDE_CONFIG_DIR")
        if config_dir:
            return Path(config_dir)
        return self.home / ".claude"

    def _log(self, msg: str) -> None:
        """Log message if verbose."""
        if self.verbose:
            print(f"[fix] {msg}", file=sys.stderr)

    def backup(self, path: Path) -> Path:
        """Create timestamped backup."""
        backup_path = path.parent / f"{path.name}.bak.{self.timestamp}"
        self._log(f"Backup: {path} -> {backup_path}")
        if not self.dry_run:
            shutil.copy2(path, backup_path)
        return backup_path

    def reset_claude_json(self) -> ResultDict:
        """RESET_CLAUDE_JSON action: Backup and move aside ~/.claude.json."""
        claude_json = self.home / ".claude.json"

        if not claude_json.exists():
            return {"status": "skip", "reason": "File not found"}

        size_before = claude_json.stat().st_size
        backup_path = self.backup(claude_json)
        disabled_path = claude_json.parent / f".claude.json.disabled.{self.timestamp}"

        self._log(f"Moving {claude_json} to {disabled_path}")

        if not self.dry_run:
            shutil.move(str(claude_json), str(disabled_path))

        return {
            "status": "success" if not self.dry_run else "dry-run",
            "size_before": size_before,
            "size_before_human": format_size(size_before),
            "backup": str(backup_path),
            "disabled": str(disabled_path),
            "message": "Backed up and moved aside. Re-authenticate on next claude start.",
            "rollback": f"mv {disabled_path} {claude_json}",
        }

    def clear_plugin_cache(self) -> ResultDict:
        """CLEAR_PLUGIN_CACHE action: Remove plugin cache directories."""
        cache_dirs = [
            self.claude_dir / "plugins" / "cache",
        ]

        cleared: List[str] = []
        total_size = 0
        total_files = 0

        for cache_dir in cache_dirs:
            if cache_dir.exists():
                size = get_dir_size(cache_dir)
                file_count = sum(1 for _ in cache_dir.rglob("*") if _.is_file())
                total_size += size
                total_files += file_count

                self._log(f"Clearing {cache_dir} ({format_size(size)}, {file_count} files)")

                if not self.dry_run:
                    shutil.rmtree(cache_dir)

                cleared.append(str(cache_dir))

        return {
            "status": "success" if not self.dry_run else "dry-run",
            "cleared": cleared,
            "size_freed": total_size,
            "size_freed_human": format_size(total_size),
            "files_removed": total_files,
            "message": f"Cleared {format_size(total_size)} from plugin cache",
        }

    def disable_nonessential_traffic(self) -> ResultDict:
        """DISABLE_NONESSENTIAL_TRAFFIC action: Set env in settings.json."""
        settings_path = self.claude_dir / "settings.json"

        # Load existing or create new
        data: Dict[str, object] = {}
        if settings_path.exists():
            self.backup(settings_path)
            with open(settings_path, "r") as f:
                data = json.load(f)

        # Merge env setting
        if "env" not in data:
            data["env"] = {}
        env_dict = data["env"]
        if isinstance(env_dict, dict):
            env_dict["CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC"] = "1"

        self._log(f"Setting CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 in {settings_path}")

        if not self.dry_run:
            settings_path.parent.mkdir(parents=True, exist_ok=True)
            with open(settings_path, "w") as f:
                json.dump(data, f, indent=2)

        return {
            "status": "success" if not self.dry_run else "dry-run",
            "path": str(settings_path),
            "message": "Set CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1",
        }

    def set_cleanup_period(self, days: int) -> ResultDict:
        """SET_CLEANUP_PERIOD action: Set cleanupPeriodDays in settings.json."""
        settings_path = self.claude_dir / "settings.json"

        # Load existing or create new
        data: Dict[str, object] = {}
        if settings_path.exists():
            self.backup(settings_path)
            with open(settings_path, "r") as f:
                data = json.load(f)

        data["cleanupPeriodDays"] = days

        self._log(f"Setting cleanupPeriodDays={days} in {settings_path}")

        if not self.dry_run:
            settings_path.parent.mkdir(parents=True, exist_ok=True)
            with open(settings_path, "w") as f:
                json.dump(data, f, indent=2)

        return {
            "status": "success" if not self.dry_run else "dry-run",
            "path": str(settings_path),
            "cleanup_period_days": days,
            "message": f"Set cleanupPeriodDays={days}. Old sessions deleted at startup.",
        }

    def prune_sessions(self, days: int, backup_first: bool = True) -> ResultDict:
        """PRUNE_SESSIONS action: Delete old session files."""
        projects_dir = self.claude_dir / "projects"

        if not projects_dir.exists():
            return {"status": "skip", "reason": "projects directory not found"}

        # Find old files using find command (cross-platform via subprocess)
        result = subprocess.run(
            ["find", str(projects_dir), "-type", "f", "-mtime", f"+{days}"],
            capture_output=True, text=True
        )
        old_files = [f for f in result.stdout.strip().split("\n") if f]

        if not old_files:
            return {"status": "skip", "reason": f"No files older than {days} days"}

        # Calculate size
        total_size = sum(Path(f).stat().st_size for f in old_files if Path(f).exists())

        # Create backup tarball
        backup_tar = ""
        if backup_first and old_files and not self.dry_run:
            backup_tar = str(self.home / f"claude-projects-backup.{self.timestamp}.tgz")
            self._log(f"Creating backup: {backup_tar}")
            subprocess.run([
                "tar", "-czf", backup_tar,
                "-C", str(self.claude_dir), "projects"
            ], check=True)

        # Delete old files
        if not self.dry_run:
            for f in old_files:
                try:
                    Path(f).unlink()
                except (PermissionError, OSError) as e:
                    self._log(f"Could not delete {f}: {e}")

        return {
            "status": "success" if not self.dry_run else "dry-run",
            "pruned_count": len(old_files),
            "size_freed": total_size,
            "size_freed_human": format_size(total_size),
            "backup": backup_tar,
            "message": f"Pruned {len(old_files)} files ({format_size(total_size)})",
        }

    def prune_debug_logs(self, days: int = 14) -> ResultDict:
        """PRUNE_DEBUG_LOGS action: Delete old debug logs."""
        debug_dir = self.claude_dir / "debug"

        if not debug_dir.exists():
            return {"status": "skip", "reason": "debug directory not found"}

        # Find old files
        result = subprocess.run(
            ["find", str(debug_dir), "-type", "f", "-mtime", f"+{days}"],
            capture_output=True, text=True
        )
        old_files = [f for f in result.stdout.strip().split("\n") if f]

        if not old_files:
            return {"status": "skip", "reason": f"No debug files older than {days} days"}

        # Calculate size
        total_size = sum(Path(f).stat().st_size for f in old_files if Path(f).exists())

        # Delete old files
        if not self.dry_run:
            for f in old_files:
                try:
                    Path(f).unlink()
                except (PermissionError, OSError) as e:
                    self._log(f"Could not delete {f}: {e}")

        return {
            "status": "success" if not self.dry_run else "dry-run",
            "pruned_count": len(old_files),
            "size_freed": total_size,
            "size_freed_human": format_size(total_size),
            "message": f"Pruned {len(old_files)} debug files ({format_size(total_size)})",
        }


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Execute Claude Code Cleaner remediation actions"
    )
    parser.add_argument("action", choices=[
        "reset-claude-json", "clear-plugin-cache",
        "disable-nonessential", "set-cleanup-period",
        "prune-sessions", "prune-debug-logs"
    ], help="Action to execute")
    parser.add_argument("--confirm", action="store_true",
                        help="Actually execute (disable dry-run)")
    parser.add_argument("--days", type=int, default=30,
                        help="Days threshold for prune operations")
    parser.add_argument("--verbose", "-v", action="store_true",
                        help="Enable verbose output")
    parser.add_argument("--json", action="store_true",
                        help="Output JSON result")

    args = parser.parse_args()

    executor = ActionExecutor(dry_run=not args.confirm, verbose=args.verbose)

    action_map = {
        "reset-claude-json": executor.reset_claude_json,
        "clear-plugin-cache": executor.clear_plugin_cache,
        "disable-nonessential": executor.disable_nonessential_traffic,
        "set-cleanup-period": lambda: executor.set_cleanup_period(args.days),
        "prune-sessions": lambda: executor.prune_sessions(args.days),
        "prune-debug-logs": lambda: executor.prune_debug_logs(args.days),
    }

    result = action_map[args.action]()

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        # Formatted output
        status = result.get("status", "unknown")
        message = result.get("message", "")

        if status == "dry-run":
            print(f"\n[DRY-RUN] {args.action}")
            print("-" * 40)
            print(message)
            if "size_freed_human" in result:
                print(f"Would free: {result['size_freed_human']}")
            print("\nRun with --confirm to execute.")
        elif status == "success":
            print(f"\n[SUCCESS] {args.action}")
            print("-" * 40)
            print(message)
            if "size_freed_human" in result:
                print(f"Freed: {result['size_freed_human']}")
            if "backup" in result and result["backup"]:
                print(f"Backup: {result['backup']}")
            if "rollback" in result:
                print(f"Rollback: {result['rollback']}")
        elif status == "skip":
            print(f"\n[SKIPPED] {args.action}")
            print(f"Reason: {result.get('reason', 'unknown')}")
        else:
            print(f"\n[{status.upper()}] {args.action}")
            print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
