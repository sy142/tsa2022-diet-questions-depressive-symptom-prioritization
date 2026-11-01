import importlib.metadata as md
import platform
import sys

print(f"Python {platform.python_version()} ({sys.executable})")
for paket in ("matplotlib", "numpy", "pandas", "openpyxl", "fonttools", "pillow"):
    try:
        print(f"{paket} {md.version(paket)}")
    except md.PackageNotFoundError:
        print(f"{paket} yok")
