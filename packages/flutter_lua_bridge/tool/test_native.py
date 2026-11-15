"""Build and run the native tests with ASan/UBSan (Clang on macOS or Linux).

Every bundled Lua release under third_party/ is tested, so the flb shim is
verified against Lua 5.3, 5.4 and 5.5 with the same sources.

    python3 tool/test_native.py            # all bundled releases
    python3 tool/test_native.py 5.4 5.5    # selected release lines
"""
from pathlib import Path
import os
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parent.parent
native = root / "native"

# Each test program and the shim sources it links against.
PROGRAMS = {
    "flb_test": ["flb.c", "flb_test.c"],
}


def bundled_releases():
    releases = sorted(
        path for path in (root / "third_party").glob("lua-*") if (path / "src" / "lua.h").is_file()
    )
    if not releases:
        sys.exit("no bundled Lua release found under third_party/")
    return releases


def run(lua_root, directory):
    source = lua_root / "src"
    lua_sources = sorted(p for p in source.glob("*.c") if p.name not in {"lua.c", "luac.c"})
    for name, files in PROGRAMS.items():
        binary = Path(directory) / f"{name}-{lua_root.name}"
        command = [
            os.environ.get("CC", "clang"), "-std=c99", "-g", "-O1",
            "-fsanitize=address,undefined", "-fno-sanitize-recover=undefined",
            "-fno-omit-frame-pointer",
            # Upstream Lua 5.3 trips this warning; the sources stay unmodified.
            "-Wno-string-plus-int",
            "-DLUA_USE_MACOSX" if sys.platform == "darwin" else "-DLUA_USE_LINUX",
            "-I" + str(source), "-I" + str(native),
            *(str(native / file) for file in files),
            *map(str, lua_sources), "-lm",
        ]
        if sys.platform != "darwin":
            command.extend(["-ldl", "-lpthread"])
        command.extend(["-o", str(binary)])
        subprocess.run(command, check=True)
        print(f"[{lua_root.name}] {name}: ", end="", flush=True)
        subprocess.run([str(binary)], check=True)


def main():
    wanted = sys.argv[1:]
    releases = [
        path for path in bundled_releases()
        if not wanted or any(
            path.name == f"lua-{version}" or path.name.startswith(f"lua-{version}.")
            for version in wanted
        )
    ]
    if not releases:
        sys.exit(f"no bundled Lua release matches: {' '.join(wanted)}")
    with tempfile.TemporaryDirectory(prefix="flb-native-") as directory:
        for lua_root in releases:
            run(lua_root, directory)


if __name__ == "__main__":
    main()
