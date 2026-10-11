#!/usr/bin/env python3
"""Build a standalone Poople addon ZIP without development files."""

from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile


ROOT = Path(__file__).resolve().parents[1]
FILES = ("Poople.toc", "Words.lua", "Game.lua", "Preferences.lua", "Poople.lua", "README.md", "THIRD_PARTY.md", "LICENSE")


def main():
    version = next(line.split(":", 1)[1].strip() for line in (ROOT / "Poople.toc").read_text().splitlines()
                   if line.startswith("## Version:"))
    output = ROOT / "dist" / f"Poople-{version}.zip"
    output.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(output, "w", compression=ZIP_DEFLATED) as archive:
        for name in FILES:
            archive.write(ROOT / name, f"Poople/{name}")
    print(output)


if __name__ == "__main__":
    main()
