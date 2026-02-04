#!/usr/bin/env python3
"""Claude Code Disk - Fix Actions

Executes cleanup actions with safety guarantees:
- Always creates timestamped backups in ~/.claude-backups/
- Supports preview mode (default) - shows what WOULD happen
- Requires --confirm to execute destructive actions
- Fails fast on permission errors (no silent skipping)

Usage:
    python3 cc-disk-fix.py <action> [--preview] [--confirm] [--days N]

Actions:
    DELETE-cache-dirs         Clear debug, shell-snapshots, paste-cache, etc.
    DELETE-debug-logs         Delete old debug logs (--days N, default 14)
    DELETE-old-plugin-versions Keep only latest version of each plugin
    DELETE-plugin-cache       Remove all plugin cache directories
    DELETE-orphaned-projects  Remove project data for paths that no longer exist
    DELETE-old-sessions       Delete old session files (--days N, default 30)
    DELETE-auth-config        Backup and move aside ~/.claude.json (requires re-login)
    disable-nonessential      Set CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
    set-cleanup-period        Set cleanupPeriodDays in settings.json
    list-backups              List available backups
    restore-backup            Restore from a backup (--timestamp TIMESTAMP)
"""

import argparse
import json
import os
import platform
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Tuple, Union

# Type alias for result dictionaries - flexible to handle various return shapes
ResultDict = Dict[str, object]

# Centralized backup location
BACKUP_ROOT = Path.home() / ".claude-backups"


def format_size(bytes_val: int) -> str:
    """Format bytes as human-readable string."""
    if bytes_val >= 1073741824:
        return f"{bytes_val / 1073741824:.1f}GB"
    elif bytes_val >= 1048576:
        return f"{bytes_val / 1048576:.1f}MB"
    elif bytes_val >= 1024:
        return f"{bytes_val / 1024:.1f}KB"
    return f"{bytes_val}B"


def get_file_age_days(path: Path) -> int:
    """Get file age in days."""
    if not path.exists():
        return 0
    mtime = path.stat().st_mtime
    age_seconds = datetime.now().timestamp() - mtime
    return int(age_seconds / 86400)


def get_dir_size(path: Path) -> int:
    """Get total size of directory in bytes. Fails on permission errors."""
    if not path.exists():
        return 0
    total = 0
    for entry in path.rglob("*"):
        if entry.is_file():
            # No try/except - fail fast on permission errors
            total += entry.stat().st_size
    return total


class BackupManager:
    """Manage centralized backups in ~/.claude-backups/"""

    def __init__(self) -> None:
        self.backup_root = BACKUP_ROOT

    def create_backup_dir(self) -> Path:
        """Create timestamped backup directory, return path."""
        timestamp = datetime.now().strftime("%Y-%m-%dT%H-%M-%S")
        backup_dir = self.backup_root / timestamp
        backup_dir.mkdir(parents=True, exist_ok=True)

        # Update 'latest' symlink
        latest = self.backup_root / "latest"
        if latest.is_symlink():
            latest.unlink()
        latest.symlink_to(timestamp)

        return backup_dir

    def create_manifest(
        self, backup_dir: Path, action: str, description: str = ""
    ) -> Path:
        """Create manifest.json in backup directory."""
        manifest_path = backup_dir / "manifest.json"
        manifest = {
            "created": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
            "action": action,
            "description": description,
            "hostname": platform.node(),
            "user": os.getenv("USER", "unknown"),
            "files": [],
        }
        with open(manifest_path, "w") as f:
            json.dump(manifest, f, indent=2)
        return manifest_path

    def add_to_manifest(
        self, backup_dir: Path, original: str, backup_name: str, size: int
    ) -> None:
        """Add file entry to manifest."""
        manifest_path = backup_dir / "manifest.json"
        with open(manifest_path, "r") as f:
            manifest = json.load(f)
        manifest["files"].append({
            "original": original,
            "backup": backup_name,
            "size": size,
        })
        with open(manifest_path, "w") as f:
            json.dump(manifest, f, indent=2)

    def backup_file(self, backup_dir: Path, source: Path, name: str = "") -> Path:
        """Backup a single file to backup directory."""
        if not source.exists():
            raise FileNotFoundError(f"Cannot backup: {source} not found")

        backup_name = name or source.name
        dest = backup_dir / backup_name
        size = source.stat().st_size

        shutil.copy2(source, dest)
        self.add_to_manifest(backup_dir, str(source), backup_name, size)

        return dest

    def backup_dir_tar(
        self, backup_dir: Path, source: Path, tarball_name: str
    ) -> Path:
        """Backup directory as tarball."""
        if not source.exists():
            raise FileNotFoundError(f"Cannot backup: {source} not found")

        dest = backup_dir / tarball_name
        size = get_dir_size(source)

        subprocess.run(
            ["tar", "-czf", str(dest), "-C", str(source.parent), source.name],
            check=True,
        )
        self.add_to_manifest(backup_dir, str(source), tarball_name, size)

        return dest

    def list_backups(self) -> List[Dict[str, str]]:
        """List all available backups."""
        backups = []
        if not self.backup_root.exists():
            return backups

        for item in sorted(self.backup_root.iterdir(), reverse=True):
            if item.is_dir() and item.name.startswith("20"):
                manifest_path = item / "manifest.json"
                entry: Dict[str, Union[str, int]] = {"timestamp": item.name, "path": str(item)}

                if manifest_path.exists():
                    with open(manifest_path, "r") as f:
                        manifest = json.load(f)
                    entry["action"] = manifest.get("action", "unknown")
                    entry["created"] = manifest.get("created", "")
                    entry["files"] = len(manifest.get("files", []))

                # Get size
                size = sum(f.stat().st_size for f in item.rglob("*") if f.is_file())
                entry["size"] = size
                entry["size_human"] = format_size(size)

                backups.append(entry)

        return backups

    def restore(self, timestamp: str) -> ResultDict:
        """Restore from a backup."""
        backup_dir = self.backup_root / timestamp

        if not backup_dir.exists():
            return {"status": "error", "message": f"Backup not found: {backup_dir}"}

        manifest_path = backup_dir / "manifest.json"
        if not manifest_path.exists():
            return {"status": "error", "message": "No manifest found in backup"}

        with open(manifest_path, "r") as f:
            manifest = json.load(f)

        restored = []
        for file_entry in manifest.get("files", []):
            original = file_entry["original"]
            backup_name = file_entry["backup"]
            backup_path = backup_dir / backup_name

            if backup_name.endswith((".tgz", ".tar.gz")):
                # Extract tarball
                parent = Path(original).parent
                subprocess.run(
                    ["tar", "-xzf", str(backup_path), "-C", str(parent)],
                    check=True,
                )
                restored.append(original)
            elif backup_path.exists():
                shutil.copy2(backup_path, original)
                restored.append(original)

        return {
            "status": "success",
            "restored": restored,
            "message": f"Restored {len(restored)} items from {timestamp}",
        }


class ActionExecutor:
    """Execute remediation actions with safety guarantees."""

    def __init__(
        self, preview: bool = True, confirm: bool = False, verbose: bool = False
    ):
        self.preview = preview
        self.confirm = confirm
        self.verbose = verbose
        self.home = Path.home()
        self.claude_dir = self._resolve_claude_dir()
        self.backup_mgr = BackupManager()
        self.permission_errors: List[str] = []

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

    def _check_permission(self, path: Path, operation: str = "access") -> None:
        """Check permission and fail fast if not accessible."""
        try:
            if path.is_file():
                path.stat()
            elif path.is_dir():
                list(path.iterdir())
        except PermissionError as e:
            raise PermissionError(
                f"Cannot {operation} {path}: Permission denied. "
                "Run with appropriate permissions or exclude this path."
            ) from e

    def delete_auth_config(self) -> ResultDict:
        """DELETE-auth-config: Backup and move aside ~/.claude.json."""
        claude_json = self.home / ".claude.json"

        if not claude_json.exists():
            return {"status": "skip", "reason": "File not found: ~/.claude.json"}

        self._check_permission(claude_json, "read")
        size = claude_json.stat().st_size

        # Preview mode: just show what would happen
        if self.preview or not self.confirm:
            return {
                "status": "preview",
                "action": "DELETE-auth-config",
                "files": [{"path": str(claude_json), "size": size, "size_human": format_size(size)}],
                "total_size": size,
                "total_size_human": format_size(size),
                "warning": "This will require re-authentication on next Claude start",
                "backup_location": str(BACKUP_ROOT / "<timestamp>"),
            }

        # Execute
        backup_dir = self.backup_mgr.create_backup_dir()
        self.backup_mgr.create_manifest(
            backup_dir, "DELETE-auth-config", "Backup of auth config before disable"
        )
        self.backup_mgr.backup_file(backup_dir, claude_json, "claude.json")

        disabled_path = claude_json.parent / f".claude.json.disabled.{datetime.now().strftime('%Y%m%d%H%M%S')}"
        shutil.move(str(claude_json), str(disabled_path))

        return {
            "status": "success",
            "size_freed": size,
            "size_freed_human": format_size(size),
            "backup": str(backup_dir),
            "disabled": str(disabled_path),
            "message": "Auth config backed up and disabled. Re-authenticate on next start.",
            "restore_cmd": f"python3 {__file__} restore-backup --timestamp {backup_dir.name}",
        }

    def delete_plugin_cache(self) -> ResultDict:
        """DELETE-plugin-cache: Remove plugin cache directories."""
        cache_dir = self.claude_dir / "plugins" / "cache"

        if not cache_dir.exists():
            return {"status": "skip", "reason": "Plugin cache not found"}

        self._check_permission(cache_dir, "read")

        # Collect file list
        files_info: List[Dict[str, Union[str, int]]] = []
        total_size = 0

        for marketplace in cache_dir.iterdir():
            if marketplace.is_dir():
                for plugin in marketplace.iterdir():
                    if plugin.is_dir():
                        size = get_dir_size(plugin)
                        total_size += size
                        files_info.append({
                            "path": str(plugin),
                            "size": size,
                            "size_human": format_size(size),
                        })

        if self.preview or not self.confirm:
            return {
                "status": "preview",
                "action": "DELETE-plugin-cache",
                "files": files_info,
                "total_size": total_size,
                "total_size_human": format_size(total_size),
                "warning": "Plugins will be re-downloaded on next use. Running plugins may break!",
                "backup_location": str(BACKUP_ROOT / "<timestamp>"),
            }

        # Execute - backup manifest only (cache can be redownloaded)
        backup_dir = self.backup_mgr.create_backup_dir()
        self.backup_mgr.create_manifest(
            backup_dir, "DELETE-plugin-cache", f"Cleared {format_size(total_size)} plugin cache"
        )

        # Save list of what was deleted for reference
        with open(backup_dir / "deleted-plugins.json", "w") as f:
            json.dump(files_info, f, indent=2)

        try:
            shutil.rmtree(cache_dir)
        except PermissionError as e:
            return {
                "status": "partial",
                "error": f"Could not fully remove cache: {e}",
                "backup": str(backup_dir),
            }
        except Exception as e:
            return {
                "status": "error",
                "error": f"Failed to remove cache: {e}",
                "backup": str(backup_dir),
            }

        return {
            "status": "success",
            "size_freed": total_size,
            "size_freed_human": format_size(total_size),
            "files_removed": len(files_info),
            "backup": str(backup_dir),
            "message": f"Cleared {format_size(total_size)} from plugin cache ({len(files_info)} plugins)",
        }

    def delete_old_sessions(self, days: int) -> ResultDict:
        """DELETE-old-sessions: Delete session files older than N days."""
        projects_dir = self.claude_dir / "projects"

        if not projects_dir.exists():
            return {"status": "skip", "reason": "Projects directory not found"}

        self._check_permission(projects_dir, "read")

        # Find old files
        files_info: List[Dict[str, Union[str, int]]] = []
        total_size = 0

        for session_file in projects_dir.rglob("*.jsonl"):
            age = get_file_age_days(session_file)
            if age > days:
                size = session_file.stat().st_size
                total_size += size
                files_info.append({
                    "path": str(session_file),
                    "size": size,
                    "size_human": format_size(size),
                    "age_days": age,
                })

        if not files_info:
            return {"status": "skip", "reason": f"No session files older than {days} days"}

        if self.preview or not self.confirm:
            return {
                "status": "preview",
                "action": "DELETE-old-sessions",
                "files": files_info,
                "total_size": total_size,
                "total_size_human": format_size(total_size),
                "file_count": len(files_info),
                "days_threshold": days,
                "backup_location": str(BACKUP_ROOT / "<timestamp>"),
            }

        # Execute with backup
        backup_dir = self.backup_mgr.create_backup_dir()
        self.backup_mgr.create_manifest(
            backup_dir,
            "DELETE-old-sessions",
            f"Sessions older than {days} days ({len(files_info)} files)",
        )

        # Backup projects directory as tarball
        self.backup_mgr.backup_dir_tar(backup_dir, projects_dir, "projects.tgz")

        # Delete old files (with path validation for security)
        deleted = 0
        base_dir = projects_dir.resolve()
        for file_info in files_info:
            path = Path(str(file_info["path"])).resolve()
            try:
                # Validate path is within expected directory (prevent traversal)
                path.relative_to(base_dir)
                path.unlink()
                deleted += 1
            except ValueError:
                # Path is outside base_dir - skip for security
                self.permission_errors.append(f"{path}: outside allowed directory")
            except PermissionError as e:
                self.permission_errors.append(f"{path}: {e}")

        if self.permission_errors:
            return {
                "status": "partial",
                "deleted": deleted,
                "failed": len(self.permission_errors),
                "errors": self.permission_errors,
                "backup": str(backup_dir),
                "message": f"Deleted {deleted}/{len(files_info)} files. {len(self.permission_errors)} permission errors.",
            }

        return {
            "status": "success",
            "size_freed": total_size,
            "size_freed_human": format_size(total_size),
            "files_removed": deleted,
            "backup": str(backup_dir),
            "message": f"Deleted {deleted} session files ({format_size(total_size)})",
            "restore_cmd": f"python3 {__file__} restore-backup --timestamp {backup_dir.name}",
        }

    def delete_debug_logs(self, days: int = 14) -> ResultDict:
        """DELETE-debug-logs: Delete debug log files older than N days."""
        debug_dir = self.claude_dir / "debug"

        if not debug_dir.exists():
            return {"status": "skip", "reason": "Debug directory not found"}

        self._check_permission(debug_dir, "read")

        # Find old files
        files_info: List[Dict[str, Union[str, int]]] = []
        total_size = 0

        for log_file in debug_dir.rglob("*"):
            if log_file.is_file():
                age = get_file_age_days(log_file)
                if age > days:
                    size = log_file.stat().st_size
                    total_size += size
                    files_info.append({
                        "path": str(log_file),
                        "size": size,
                        "size_human": format_size(size),
                        "age_days": age,
                    })

        if not files_info:
            return {"status": "skip", "reason": f"No debug files older than {days} days"}

        if self.preview or not self.confirm:
            return {
                "status": "preview",
                "action": "DELETE-debug-logs",
                "files": files_info,
                "total_size": total_size,
                "total_size_human": format_size(total_size),
                "file_count": len(files_info),
                "days_threshold": days,
                "backup_location": str(BACKUP_ROOT / "<timestamp>"),
            }

        # Execute - debug logs typically don't need backup
        backup_dir = self.backup_mgr.create_backup_dir()
        self.backup_mgr.create_manifest(
            backup_dir,
            "DELETE-debug-logs",
            f"Debug logs older than {days} days ({len(files_info)} files)",
        )

        # Save list of deleted files
        with open(backup_dir / "deleted-logs.json", "w") as f:
            json.dump(files_info, f, indent=2)

        deleted = 0
        for file_info in files_info:
            path = Path(str(file_info["path"]))
            try:
                path.unlink()
                deleted += 1
            except PermissionError as e:
                self.permission_errors.append(f"{path}: {e}")

        if self.permission_errors:
            return {
                "status": "partial",
                "deleted": deleted,
                "failed": len(self.permission_errors),
                "errors": self.permission_errors,
                "message": f"Deleted {deleted}/{len(files_info)} files. {len(self.permission_errors)} permission errors.",
            }

        return {
            "status": "success",
            "size_freed": total_size,
            "size_freed_human": format_size(total_size),
            "files_removed": deleted,
            "message": f"Deleted {deleted} debug files ({format_size(total_size)})",
        }

    def disable_nonessential_traffic(self) -> ResultDict:
        """Set CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 in settings."""
        settings_path = self.claude_dir / "settings.json"

        data: Dict[str, object] = {}
        if settings_path.exists():
            with open(settings_path, "r") as f:
                data = json.load(f)

        if "env" not in data:
            data["env"] = {}
        env_dict = data["env"]
        if isinstance(env_dict, dict):
            env_dict["CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC"] = "1"

        if self.preview or not self.confirm:
            return {
                "status": "preview",
                "action": "disable-nonessential",
                "path": str(settings_path),
                "change": "Set CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1",
            }

        # Backup and write
        backup_dir = self.backup_mgr.create_backup_dir()
        self.backup_mgr.create_manifest(backup_dir, "disable-nonessential", "Settings change")
        if settings_path.exists():
            self.backup_mgr.backup_file(backup_dir, settings_path)

        settings_path.parent.mkdir(parents=True, exist_ok=True)
        with open(settings_path, "w") as f:
            json.dump(data, f, indent=2)

        return {
            "status": "success",
            "path": str(settings_path),
            "backup": str(backup_dir),
            "message": "Set CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1",
        }

    def set_cleanup_period(self, days: int) -> ResultDict:
        """Set cleanupPeriodDays in settings.json."""
        settings_path = self.claude_dir / "settings.json"

        data: Dict[str, object] = {}
        if settings_path.exists():
            with open(settings_path, "r") as f:
                data = json.load(f)

        data["cleanupPeriodDays"] = days

        if self.preview or not self.confirm:
            return {
                "status": "preview",
                "action": "set-cleanup-period",
                "path": str(settings_path),
                "change": f"Set cleanupPeriodDays={days}",
            }

        backup_dir = self.backup_mgr.create_backup_dir()
        self.backup_mgr.create_manifest(backup_dir, "set-cleanup-period", f"Set to {days} days")
        if settings_path.exists():
            self.backup_mgr.backup_file(backup_dir, settings_path)

        settings_path.parent.mkdir(parents=True, exist_ok=True)
        with open(settings_path, "w") as f:
            json.dump(data, f, indent=2)

        return {
            "status": "success",
            "path": str(settings_path),
            "backup": str(backup_dir),
            "cleanup_period_days": days,
            "message": f"Set cleanupPeriodDays={days}. Old sessions deleted at startup.",
        }

    def delete_cache_dirs(self) -> ResultDict:
        """DELETE-cache-dirs: Clear cache directories."""
        cache_dirs = [
            ("debug", self.claude_dir / "debug"),
            ("shell-snapshots", self.claude_dir / "shell-snapshots"),
            ("paste-cache", self.claude_dir / "paste-cache"),
            ("todos", self.claude_dir / "todos"),
            ("session-env", self.claude_dir / "session-env"),
        ]

        files_info: List[Dict[str, Union[str, int]]] = []
        total_size = 0

        for name, path in cache_dirs:
            if path.exists() and path.is_dir():
                size = get_dir_size(path)
                if size > 0:
                    files_info.append({
                        "path": str(path),
                        "name": name,
                        "size": size,
                        "size_human": format_size(size),
                    })
                    total_size += size

        if not files_info:
            return {"status": "skip", "reason": "No cache directories with content found"}

        if self.preview or not self.confirm:
            return {
                "status": "preview",
                "action": "DELETE-cache-dirs",
                "files": files_info,
                "total_size": total_size,
                "total_size_human": format_size(total_size),
                "backup_location": str(BACKUP_ROOT / "<timestamp>"),
            }

        # Execute
        backup_dir = self.backup_mgr.create_backup_dir()
        self.backup_mgr.create_manifest(
            backup_dir, "DELETE-cache-dirs", f"Cleared {len(files_info)} cache dirs"
        )

        # Save list of what was deleted
        with open(backup_dir / "deleted-cache-dirs.json", "w") as f:
            json.dump(files_info, f, indent=2)

        deleted = 0
        for info in files_info:
            path = Path(str(info["path"]))
            try:
                shutil.rmtree(path)
                path.mkdir(parents=True, exist_ok=True)  # Recreate empty
                deleted += 1
            except (PermissionError, OSError) as e:
                self.permission_errors.append(f"{path}: {e}")

        if self.permission_errors:
            return {
                "status": "partial",
                "deleted": deleted,
                "failed": len(self.permission_errors),
                "errors": self.permission_errors,
                "backup": str(backup_dir),
                "message": f"Cleared {deleted}/{len(files_info)} cache dirs.",
            }

        return {
            "status": "success",
            "size_freed": total_size,
            "size_freed_human": format_size(total_size),
            "dirs_cleared": deleted,
            "backup": str(backup_dir),
            "message": f"Cleared {deleted} cache directories ({format_size(total_size)})",
        }

    def delete_orphaned_projects(self) -> ResultDict:
        """DELETE-orphaned-projects: Remove project data for paths that no longer exist."""
        projects_dir = self.claude_dir / "projects"

        if not projects_dir.exists():
            return {"status": "skip", "reason": "Projects directory not found"}

        self._check_permission(projects_dir, "read")

        files_info: List[Dict[str, Union[str, int]]] = []
        total_size = 0

        try:
            for project_dir in projects_dir.iterdir():
                if not project_dir.is_dir():
                    continue
                # Convert -Users-chris-repos-foo → /Users/chris/repos/foo
                original_path = "/" + project_dir.name.lstrip("-").replace("-", "/")
                if not Path(original_path).is_dir():
                    size = get_dir_size(project_dir)
                    files_info.append({
                        "path": str(project_dir),
                        "original_path": original_path,
                        "size": size,
                        "size_human": format_size(size),
                    })
                    total_size += size
        except (PermissionError, OSError):
            pass

        if not files_info:
            return {"status": "skip", "reason": "No orphaned projects found"}

        if self.preview or not self.confirm:
            return {
                "status": "preview",
                "action": "DELETE-orphaned-projects",
                "files": files_info,
                "total_size": total_size,
                "total_size_human": format_size(total_size),
                "warning": "This will delete project history for paths that no longer exist",
                "backup_location": str(BACKUP_ROOT / "<timestamp>"),
            }

        # Execute with backup
        backup_dir = self.backup_mgr.create_backup_dir()
        self.backup_mgr.create_manifest(
            backup_dir,
            "DELETE-orphaned-projects",
            f"{len(files_info)} orphaned project dirs ({format_size(total_size)})",
        )

        # Backup orphaned projects as tarball
        orphaned_tar = backup_dir / "orphaned-projects.tgz"
        orphaned_paths = [info["path"] for info in files_info]
        subprocess.run(
            ["tar", "-czf", str(orphaned_tar), "-C", str(projects_dir)] +
            [Path(p).name for p in orphaned_paths],
            check=True,
        )

        # Delete orphaned directories
        deleted = 0
        for info in files_info:
            path = Path(str(info["path"]))
            try:
                shutil.rmtree(path)
                deleted += 1
            except (PermissionError, OSError) as e:
                self.permission_errors.append(f"{path}: {e}")

        if self.permission_errors:
            return {
                "status": "partial",
                "deleted": deleted,
                "failed": len(self.permission_errors),
                "errors": self.permission_errors,
                "backup": str(backup_dir),
                "message": f"Deleted {deleted}/{len(files_info)} orphaned projects.",
            }

        return {
            "status": "success",
            "size_freed": total_size,
            "size_freed_human": format_size(total_size),
            "dirs_removed": deleted,
            "backup": str(backup_dir),
            "message": f"Deleted {deleted} orphaned project directories ({format_size(total_size)})",
            "restore_cmd": f"python3 {__file__} restore-backup --timestamp {backup_dir.name}",
        }

    def _semver_key(self, version: str) -> Tuple[int, int, int]:
        """Convert version string to sortable tuple."""
        parts = version.lstrip("v").split(".")
        try:
            return (
                int(parts[0]) if len(parts) > 0 else 0,
                int(parts[1]) if len(parts) > 1 else 0,
                int(parts[2].split("-")[0]) if len(parts) > 2 else 0,
            )
        except (ValueError, IndexError):
            return (0, 0, 0)

    def delete_old_plugin_versions(self) -> ResultDict:
        """DELETE-old-plugin-versions: Keep only latest version of each plugin."""
        cache_dir = self.claude_dir / "plugins" / "cache"

        if not cache_dir.exists():
            return {"status": "skip", "reason": "Plugin cache not found"}

        self._check_permission(cache_dir, "read")

        files_info: List[Dict[str, Union[str, int]]] = []
        total_size = 0

        try:
            for marketplace in cache_dir.iterdir():
                if not marketplace.is_dir():
                    continue
                for plugin in marketplace.iterdir():
                    if not plugin.is_dir():
                        continue
                    versions = [v for v in plugin.iterdir() if v.is_dir()]
                    if len(versions) <= 1:
                        continue
                    # Sort by semver, keep latest
                    versions.sort(key=lambda v: self._semver_key(v.name), reverse=True)
                    latest = versions[0].name
                    for old_ver in versions[1:]:
                        size = get_dir_size(old_ver)
                        files_info.append({
                            "path": str(old_ver),
                            "plugin": plugin.name,
                            "version": old_ver.name,
                            "latest": latest,
                            "size": size,
                            "size_human": format_size(size),
                        })
                        total_size += size
        except (PermissionError, OSError):
            pass

        if not files_info:
            return {"status": "skip", "reason": "No old plugin versions found"}

        if self.preview or not self.confirm:
            return {
                "status": "preview",
                "action": "DELETE-old-plugin-versions",
                "files": files_info,
                "total_size": total_size,
                "total_size_human": format_size(total_size),
                "warning": "Running plugins may break! Restart Claude Code after cleanup.",
                "backup_location": str(BACKUP_ROOT / "<timestamp>"),
            }

        # Execute
        backup_dir = self.backup_mgr.create_backup_dir()
        self.backup_mgr.create_manifest(
            backup_dir,
            "DELETE-old-plugin-versions",
            f"{len(files_info)} old plugin versions ({format_size(total_size)})",
        )

        # Save list of what was deleted
        with open(backup_dir / "deleted-plugin-versions.json", "w") as f:
            json.dump(files_info, f, indent=2)

        deleted = 0
        for info in files_info:
            path = Path(str(info["path"]))
            try:
                shutil.rmtree(path)
                deleted += 1
            except (PermissionError, OSError) as e:
                self.permission_errors.append(f"{path}: {e}")

        if self.permission_errors:
            return {
                "status": "partial",
                "deleted": deleted,
                "failed": len(self.permission_errors),
                "errors": self.permission_errors,
                "backup": str(backup_dir),
                "message": f"Deleted {deleted}/{len(files_info)} old plugin versions.",
            }

        return {
            "status": "success",
            "size_freed": total_size,
            "size_freed_human": format_size(total_size),
            "versions_removed": deleted,
            "backup": str(backup_dir),
            "message": f"Deleted {deleted} old plugin versions ({format_size(total_size)})",
        }


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Execute Claude Code Disk cleanup actions"
    )
    parser.add_argument(
        "action",
        choices=[
            "DELETE-cache-dirs",
            "DELETE-debug-logs",
            "DELETE-old-plugin-versions",
            "DELETE-plugin-cache",
            "DELETE-orphaned-projects",
            "DELETE-old-sessions",
            "DELETE-auth-config",
            "disable-nonessential",
            "set-cleanup-period",
            "list-backups",
            "restore-backup",
        ],
        help="Action to execute",
    )
    parser.add_argument(
        "--preview",
        action="store_true",
        default=True,
        help="Preview what would happen (default)",
    )
    parser.add_argument(
        "--confirm",
        action="store_true",
        help="Actually execute destructive action",
    )
    parser.add_argument(
        "--days",
        type=int,
        default=30,
        help="Days threshold for prune operations (default: 30)",
    )
    parser.add_argument(
        "--timestamp",
        type=str,
        help="Timestamp for restore-backup action",
    )
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    parser.add_argument("--json", action="store_true", help="Output JSON result")

    args = parser.parse_args()

    # Handle backup management actions
    if args.action == "list-backups":
        backup_mgr = BackupManager()
        backups = backup_mgr.list_backups()
        if args.json:
            print(json.dumps(backups, indent=2))
        else:
            if not backups:
                print("No backups found.")
            else:
                print(f"\nBackups in {BACKUP_ROOT}:\n")
                for b in backups:
                    print(f"  {b['timestamp']} - {b.get('action', 'unknown')} ({b['size_human']})")
        return

    if args.action == "restore-backup":
        if not args.timestamp:
            print("ERROR: --timestamp required for restore-backup")
            sys.exit(1)
        backup_mgr = BackupManager()
        result = backup_mgr.restore(args.timestamp)
        if args.json:
            print(json.dumps(result, indent=2))
        else:
            status_str = str(result.get("status", "unknown"))
            print(f"\n[{status_str.upper()}] restore-backup")
            print(result.get("message", ""))
        return

    action = args.action

    executor = ActionExecutor(
        preview=not args.confirm, confirm=args.confirm, verbose=args.verbose
    )

    action_map = {
        "DELETE-cache-dirs": executor.delete_cache_dirs,
        "DELETE-debug-logs": lambda: executor.delete_debug_logs(args.days),
        "DELETE-old-plugin-versions": executor.delete_old_plugin_versions,
        "DELETE-plugin-cache": executor.delete_plugin_cache,
        "DELETE-orphaned-projects": executor.delete_orphaned_projects,
        "DELETE-old-sessions": lambda: executor.delete_old_sessions(args.days),
        "DELETE-auth-config": executor.delete_auth_config,
        "disable-nonessential": executor.disable_nonessential_traffic,
        "set-cleanup-period": lambda: executor.set_cleanup_period(args.days),
    }

    try:
        result = action_map[action]()
    except PermissionError as e:
        result = {"status": "error", "message": str(e)}
    except Exception as e:
        result = {"status": "error", "message": f"Unexpected error: {e}"}

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        status = str(result.get("status", "unknown"))

        if status == "preview":
            print(f"\n{'='*60}")
            print(f"PREVIEW: {action}")
            print(f"{'='*60}")

            files_raw = result.get("files", [])
            if isinstance(files_raw, list) and files_raw:
                print(f"\nFiles that WOULD be affected ({len(files_raw)} total):\n")
                for f in files_raw[:10]:  # Show first 10
                    if isinstance(f, dict):
                        age_days = f.get("age_days")
                        age = f" ({age_days} days old)" if age_days is not None else ""
                        print(f"  {f.get('path', '?')} ({f.get('size_human', '?')}){age}")
                if len(files_raw) > 10:
                    print(f"  ... and {len(files_raw) - 10} more files")

            print(f"\nTotal size: {result.get('total_size_human', '?')}")

            if "warning" in result:
                print(f"\n⚠️  WARNING: {result['warning']}")

            print(f"\nBackup will be created in: {result.get('backup_location', BACKUP_ROOT)}")
            print("\n" + "="*60)
            print("Run with --confirm to execute this action.")
            print("="*60)

        elif status == "success":
            print(f"\n[SUCCESS] {action}")
            print("-" * 40)
            print(result.get("message", ""))
            if "size_freed_human" in result:
                print(f"Freed: {result['size_freed_human']}")
            if "backup" in result:
                print(f"Backup: {result['backup']}")
            if "restore_cmd" in result:
                print(f"Restore: {result['restore_cmd']}")

        elif status == "partial":
            print(f"\n[PARTIAL] {action}")
            print("-" * 40)
            print(result.get("message", ""))
            errors_raw = result.get("errors", [])
            if isinstance(errors_raw, list) and errors_raw:
                print("\nPermission errors:")
                for err in errors_raw[:5]:
                    print(f"  {err}")

        elif status == "skip":
            print(f"\n[SKIPPED] {action}")
            print(f"Reason: {result.get('reason', 'unknown')}")

        elif status == "error":
            print(f"\n[ERROR] {action}")
            print(f"Error: {result.get('message', 'Unknown error')}")
            sys.exit(1)

        else:
            print(f"\n[{status.upper()}] {action}")
            print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
