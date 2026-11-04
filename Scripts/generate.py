import argparse
import base64
import hashlib
import io
import json
from pathlib import Path
import re
import shutil
import tarfile
import tempfile
import urllib.request
import xml.etree.ElementTree as ET


VERSION = "1.68.0"
INTEGRITY = "sInxhr771A4UUu8D1gXZjj3mmGwqRTYDVNbfwN25Yx6vwA9Hnq9t+P9rF49UW8MirAe1iaYpqe+3vq99bbH8zg=="
ROOT = Path(__file__).resolve().parents[1]


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n")


def load_selection(path):
    names = json.loads(path.read_text())
    if not isinstance(names, list) or not names:
        raise ValueError("Icon selection must be a non-empty JSON array")
    if any(not isinstance(name, str) or not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", name) for name in names):
        raise ValueError("Icon selection must contain Lucide kebab-case names")
    if len(names) != len(set(names)):
        raise ValueError("Icon selection contains duplicate names")
    return set(names)


def generate(package_root=ROOT, archive_path=None, selection_path=None):
    selected = load_selection(selection_path) if selection_path is not None else None
    source = package_root / "Sources/LucideIcons"
    url = f"https://registry.npmjs.org/lucide-static/-/lucide-static-{VERSION}.tgz"
    if archive_path is None:
        with urllib.request.urlopen(url, timeout=60) as response:
            archive_bytes = response.read()
    else:
        archive_bytes = archive_path.read_bytes()
    digest = base64.b64encode(hashlib.sha512(archive_bytes).digest()).decode()
    if digest != INTEGRITY:
        raise ValueError("Upstream archive integrity mismatch")

    with tempfile.TemporaryDirectory() as temporary:
        staging = Path(temporary)
        catalog = staging / "Lucide.xcassets"
        catalog.mkdir()
        write_json(catalog / "Contents.json", {"info": {"author": "xcode", "version": 1}})
        cases = []
        identifiers = set()
        with tarfile.open(fileobj=io.BytesIO(archive_bytes), mode="r:gz") as archive:
            members = sorted(
                (member for member in archive.getmembers()
                 if member.isfile() and re.fullmatch(r"package/icons/[a-z0-9-]+\.svg", member.name)),
                key=lambda item: item.name,
            )
            available = {Path(member.name).stem for member in members}
            if selected is None:
                selected = available
            missing = selected - available
            if missing:
                raise ValueError(f"Unknown Lucide icons: {', '.join(sorted(missing))}")
            for member in members:
                name = Path(member.name).stem
                parts = name.split("-")
                identifier = parts[0] + "".join(part.capitalize() for part in parts[1:])
                if identifier[0].isdigit():
                    identifier = "icon" + identifier
                if identifier in identifiers:
                    identifier = name.replace("-", "_")
                if identifier in identifiers:
                    raise ValueError(f"Duplicate Swift identifier: {identifier}")
                identifiers.add(identifier)
                if name not in selected:
                    continue
                svg = archive.extractfile(member).read().decode()
                if ET.fromstring(svg).attrib.get("viewBox") != "0 0 24 24":
                    raise ValueError(f"Unexpected viewBox: {name}")
                svg = svg.replace("currentColor", "#000000")
                asset = catalog / f"lucide-{name}.imageset"
                asset.mkdir()
                (asset / f"{name}.svg").write_text(svg)
                write_json(asset / "Contents.json", {
                    "images": [{"filename": f"{name}.svg", "idiom": "universal"}],
                    "info": {"author": "xcode", "version": 1},
                    "properties": {"preserves-vector-representation": True, "template-rendering-intent": "template"},
                })
                cases.append(f'    case `{identifier}` = "{name}"')
            license_text = archive.extractfile("package/LICENSE").read().decode()
        if not cases:
            raise ValueError("No icons found")
        resources = source / "Resources"
        resources.mkdir(parents=True, exist_ok=True)
        destination = resources / "Lucide.xcassets"
        if destination.exists():
            shutil.rmtree(destination)
        shutil.copytree(catalog, destination)
        (resources / "Lucide-LICENSE.txt").write_text(license_text)
        (source / "LucideIconName.generated.swift").write_text(
            "public enum LucideIconName: String, CaseIterable, Sendable {\n"
            + "\n".join(cases) + "\n}\n"
        )
        write_json(package_root / "upstream.json", {
            "package": "lucide-static", "version": VERSION, "url": url,
            "integrity": "sha512-" + INTEGRITY, "iconCount": len(cases),
            "upstreamIconCount": len(available),
            "selectedIcons": sorted(selected) if selection_path is not None else "all",
            "generator": {"repository": "https://github.com/nix1024/lucide-icons-swiftui", "version": "0.1.0"},
        })
        if package_root.resolve() != ROOT.resolve():
            for name in ["Package.swift", "LICENSE"]:
                shutil.copyfile(ROOT / name, package_root / name)
            for path in (ROOT / "Sources/LucideIcons").glob("*.swift"):
                if path.name != "LucideIconName.generated.swift":
                    shutil.copyfile(path, source / path.name)
            shutil.copytree(ROOT / "Tests", package_root / "Tests", dirs_exist_ok=True)
        print(f"Generated {len(cases)} of {len(available)} icons from lucide-static {VERSION}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate all Lucide icons or export a standalone subset package")
    parser.add_argument("--archive", type=Path, help="Use a local npm archive (SHA-512 is still verified)")
    parser.add_argument("--icons", type=Path, help="JSON array of selected Lucide names; omitted means all icons")
    parser.add_argument("--output", type=Path, default=ROOT, help="Package output directory")
    arguments = parser.parse_args()
    generate(arguments.output, arguments.archive, arguments.icons)
