#!/usr/bin/env python3
"""Verify a local release package against a GitHub recursive Git tree JSON.

The release MANIFEST.json is the package inventory. Repository-only historical
tests and superseded audit records may remain in Git, but raw canonical ForeverDB
snapshots are prohibited from both scopes.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

FORBIDDEN_REPOSITORY_PATHS = {
    "data/ForeverDB-Canonical-1.60.1.70862.json",
    "data/ForeverDB-Canonical-1.60.1.70888.json",
    "data/ForeverDB-Canonical-1.60.1.70938.json",
}
ALLOWED_REPOSITORY_ONLY_EXACT = {
    "MODULOMARKET-RUNTIME-AUDIT-0.7.9.md",
}


def git_blob_sha1(path: Path) -> str:
    data = path.read_bytes()
    header = f"blob {len(data)}\0".encode("ascii")
    return hashlib.sha1(header + data).hexdigest()


def verify_repository_tree(package_root: Path, tree_document: dict) -> tuple[list[str], dict]:
    errors: list[str] = []
    tree = tree_document.get("tree")
    if not isinstance(tree, list):
        return ["Git tree document has no tree array"], {}
    if tree_document.get("truncated") is True:
        errors.append("GitHub recursive tree is truncated; complete inventory cannot be verified")

    entries = {item.get("path"): item for item in tree if item.get("type") == "blob"}
    remote_paths = set(entries)
    for path in sorted(FORBIDDEN_REPOSITORY_PATHS & remote_paths):
        errors.append(f"Forbidden unfiltered canonical snapshot remains in repository: {path}")

    manifest_path = package_root / "MANIFEST.json"
    if not manifest_path.is_file():
        return errors + ["Package MANIFEST.json is missing"], {}
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except Exception as exc:
        return errors + [f"Cannot parse package MANIFEST.json: {exc}"], {}

    declared_list = manifest.get("files")
    if not isinstance(declared_list, list) or not all(isinstance(x, str) for x in declared_list):
        return errors + ["MANIFEST.json files must be an array of repository-relative paths"], {}
    declared = set(declared_list)
    if len(declared) != len(declared_list):
        errors.append("MANIFEST.json contains duplicate paths")
    if manifest.get("file_count") != len(declared_list):
        errors.append("MANIFEST.json file_count does not match its files array")

    actual_missing = []
    hash_mismatches = []
    for rel in sorted(declared):
        local_path = package_root / rel
        if not local_path.is_file():
            actual_missing.append(rel)
            continue
        remote = entries.get(rel)
        if remote is None:
            errors.append(f"Release-manifest file missing from Git tree: {rel}")
            continue
        local_sha = git_blob_sha1(local_path)
        if remote.get("sha") != local_sha:
            hash_mismatches.append({
                "path": rel,
                "local_git_blob_sha1": local_sha,
                "remote_git_blob_sha1": remote.get("sha"),
            })
    for rel in actual_missing:
        errors.append(f"Release-manifest file missing from local package root: {rel}")
    for mismatch in hash_mismatches:
        errors.append(
            f"Git blob mismatch for {mismatch['path']}: "
            f"local={mismatch['local_git_blob_sha1']} remote={mismatch['remote_git_blob_sha1']}"
        )

    extras = sorted(remote_paths - declared)
    unclassified = [
        path for path in extras
        if not path.startswith("tests/") and path not in ALLOWED_REPOSITORY_ONLY_EXACT
    ]
    for path in unclassified:
        errors.append(f"Unclassified repository-only path (not in release manifest): {path}")

    summary = {
        "tree_sha": tree_document.get("sha"),
        "tree_entries": len(tree),
        "repository_blobs": len(remote_paths),
        "release_manifest_files": len(declared),
        "repository_only_files": len(extras),
        "repository_only_paths": extras,
        "git_blob_hashes_checked": len(declared) - len(actual_missing),
        "git_blob_hash_mismatches": len(hash_mismatches),
        "forbidden_snapshots_present": sorted(FORBIDDEN_REPOSITORY_PATHS & remote_paths),
    }
    return errors, summary


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--package-root", type=Path, required=True,
                        help="Directory containing MANIFEST.json and the release package files")
    parser.add_argument("--tree-json", type=Path, required=True,
                        help="JSON from GET /repos/{owner}/{repo}/git/trees/{ref}?recursive=1")
    args = parser.parse_args()
    document = json.loads(args.tree_json.read_text(encoding="utf-8"))
    errors, summary = verify_repository_tree(args.package_root, document)
    print(json.dumps({"summary": summary, "errors": errors}, indent=2))
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
