import base64
import hashlib
import io
import json
from pathlib import Path
import tarfile
import tempfile
import unittest
from unittest.mock import patch

import generate


class GenerationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.archive = self.root / "icons.tgz"
        with tarfile.open(self.archive, "w:gz") as archive:
            files = {"package/LICENSE": "Upstream license"}
            for name in ["history", "x", "arrow-down-0-1", "arrow-down-01"]:
                files[f"package/icons/{name}.svg"] = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" stroke="currentColor"/>'
            for name, content in files.items():
                payload = content.encode()
                member = tarfile.TarInfo(name)
                member.size = len(payload)
                archive.addfile(member, io.BytesIO(payload))
        integrity = base64.b64encode(hashlib.sha512(self.archive.read_bytes()).digest()).decode()
        patcher = patch.object(generate, "INTEGRITY", integrity)
        patcher.start()
        self.addCleanup(patcher.stop)

    def select(self, names):
        (self.root / "icons.json").write_text(json.dumps(names))

    def run_generation(self):
        generate.generate(self.root, self.archive, self.root / "icons.json")

    def snapshot(self):
        return {str(path.relative_to(self.root)): path.read_bytes()
                for path in (self.root / "Sources").rglob("*") if path.is_file()}

    def test_subset_removes_stale_assets_and_resources(self):
        self.select(["history", "x"])
        self.run_generation()
        self.select(["history"])
        self.run_generation()
        source = self.root / "Sources/LucideIcons"
        assets = source / "Resources/Lucide.xcassets"
        self.assertEqual([path.name for path in assets.glob("*.imageset")], ["lucide-history.imageset"])
        resources = (source / "LucideIconResource.generated.swift").read_text()
        self.assertIn('static var `history`: Self { Self(asset: "lucide-history", bundle: .module) }', resources)
        self.assertNotIn('static var `x`', resources)
        catalog = (source / "LucideIconCatalog.generated.swift").read_text()
        self.assertIn('"history": .`history`', catalog)
        self.assertNotIn('"x":', catalog)
        self.assertFalse((source / "LucideIconName.generated.swift").exists())
        self.assertEqual((source / "Resources/Lucide-LICENSE.txt").read_text(), "Upstream license")
        before = self.snapshot()
        self.run_generation()
        self.assertEqual(before, self.snapshot())

    def test_invalid_selection_preserves_previous_output(self):
        self.select(["history"])
        self.run_generation()
        before = self.snapshot()
        for names in [[], ["missing"], ["history", "history"], [None], {"icons": []}]:
            with self.subTest(names=names):
                self.select(names)
                with self.assertRaises(ValueError):
                    self.run_generation()
                self.assertEqual(before, self.snapshot())

    def test_alias_identifier_does_not_depend_on_selection(self):
        self.select(["arrow-down-01"])
        self.run_generation()
        resources = (self.root / "Sources/LucideIcons/LucideIconResource.generated.swift").read_text()
        self.assertIn('static var `arrow_down_01`:', resources)
        self.assertIn('Self(asset: "lucide-arrow-down-01", bundle: .module)', resources)

    def test_regeneration_removes_legacy_enum(self):
        source = self.root / "Sources/LucideIcons"
        source.mkdir(parents=True)
        legacy = source / "LucideIconName.generated.swift"
        legacy.write_text("public enum LucideIconName {}\n")
        self.select(["history"])
        self.run_generation()
        self.assertFalse(legacy.exists())

    def test_full_package_and_subset_export(self):
        generate.generate(self.root, self.archive)
        metadata = json.loads((self.root / "upstream.json").read_text())
        self.assertEqual(metadata["iconCount"], 4)
        self.assertEqual(metadata["selectedIcons"], "all")
        self.assertTrue((self.root / "Package.swift").is_file())
        self.assertTrue((self.root / "LICENSE").is_file())
        self.assertTrue((self.root / "Sources/LucideIcons/LucideIcon.swift").is_file())
        self.assertTrue((self.root / "Sources/LucideIcons/LucideIconResource.swift").is_file())
        self.assertTrue((self.root / "Tests/LucideIconsTests/LucideIconsTests.swift").is_file())
        self.assertTrue((self.root / "Tests/CustomIconTests/Resources/Custom.xcassets/Contents.json").is_file())

    def test_invalid_archive_preserves_previous_output(self):
        self.select(["history"])
        self.run_generation()
        before = self.snapshot()
        self.archive.write_bytes(b"corrupt archive")
        with self.assertRaisesRegex(ValueError, "integrity mismatch"):
            self.run_generation()
        self.assertEqual(before, self.snapshot())


if __name__ == "__main__":
    unittest.main()
