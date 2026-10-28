"""Build/run the native boundary with ASan/UBSan (Clang on macOS or Linux)."""
from pathlib import Path
import os
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parent.parent
sources = sorted(p for p in (root / "lua_src/src").glob("*.c") if p.name not in {"lua.c", "luac.c"})
with tempfile.TemporaryDirectory(prefix="flb-native-") as directory:
    binary = Path(directory) / "bridge_test"
    command = [
        os.environ.get("CC", "clang"), "-std=c99", "-g", "-O1",
        "-fsanitize=address,undefined", "-fno-omit-frame-pointer",
        "-DLUA_USE_MACOSX" if sys.platform == "darwin" else "-DLUA_USE_LINUX",
        "-I" + str(root / "lua_src/src"), "-I" + str(root / "native"),
        str(root / "native/bridge.c"), str(root / "native/bridge_test.c"),
        *map(str, sources), "-lm",
    ]
    if sys.platform != "darwin":
        command.append("-ldl")
    command.extend(["-o", str(binary)])
    subprocess.run(command, check=True)
    subprocess.run([str(binary)], check=True)
