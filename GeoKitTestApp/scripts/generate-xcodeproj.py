#!/usr/bin/env python3
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
PBX = ROOT / "GeoKitTestApp.xcodeproj/project.pbxproj"
SCHEME = ROOT / "GeoKitTestApp.xcodeproj/xcshareddata/xcschemes/GeoKitTestApp.xcscheme"
PBX.parent.mkdir(parents=True, exist_ok=True)
SCHEME.parent.mkdir(parents=True, exist_ok=True)
PBX.write_text((ROOT / "project.pbxproj.template").read_text())
SCHEME.write_text((ROOT / "GeoKitTestApp.xcscheme.template").read_text())
print("wrote", PBX.stat().st_size)
