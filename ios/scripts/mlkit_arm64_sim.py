#!/usr/bin/env python3
"""Build arm64-simulator variants of the MLKit static frameworks.

Google's MLKit pods ship fat .framework bundles with an arm64 slice built for
device and an x86_64 slice built for the simulator. There is no arm64-simulator
slice, so the podspecs set EXCLUDED_ARCHS[iphonesimulator]=arm64, which makes
Xcode drop the Pods-Runner umbrella target on arm64-only simulators (iOS 26+).

Every slice is a static archive, so the device arm64 code links fine against a
simulator target once its Mach-O load commands say so. This rewrites the
LC_BUILD_VERSION platform of each arm64 object from IOS to IOSSIMULATOR -- a
4-byte edit that leaves every offset in the file untouched -- and writes the
result to a sibling Frameworks-sim directory. The original device slices are
never modified; the Podfile points the simulator-only framework search path at
Frameworks-sim.
"""

import shutil
import struct
import subprocess
import sys
from pathlib import Path

MH_MAGIC_64 = 0xFEEDFACF
CPU_TYPE_ARM64 = 0x0100000C
MH_OBJECT = 1
LC_BUILD_VERSION = 0x32
PLATFORM_IOS = 2
PLATFORM_IOSSIMULATOR = 7


def retarget_to_simulator(blob: bytearray) -> int:
    """Flip every arm64 object's LC_BUILD_VERSION from iOS to iOS Simulator.

    Scans for Mach-O headers rather than parsing the ar container, which lets
    the same code handle both archive members and bare object files.
    """
    patched = 0
    for pos in range(0, len(blob) - 32, 4):
        if struct.unpack_from("<I", blob, pos)[0] != MH_MAGIC_64:
            continue
        cputype, _, filetype, ncmds = struct.unpack_from("<iiII", blob, pos + 4)
        if cputype != CPU_TYPE_ARM64 or filetype != MH_OBJECT:
            continue

        off = pos + 32
        for _ in range(ncmds):
            if off + 8 > len(blob):
                break
            cmd, cmdsize = struct.unpack_from("<II", blob, off)
            if cmdsize < 8:
                break
            if cmd == LC_BUILD_VERSION:
                if struct.unpack_from("<I", blob, off + 8)[0] == PLATFORM_IOS:
                    struct.pack_into("<I", blob, off + 8, PLATFORM_IOSSIMULATOR)
                    patched += 1
                break
            off += cmdsize
    return patched


def slice_out(binary: Path, arch: str, dest: Path) -> bool:
    probe = subprocess.run(
        ["lipo", "-archs", str(binary)], capture_output=True, text=True
    )
    if arch not in probe.stdout.split():
        return False
    if len(probe.stdout.split()) == 1:
        shutil.copy2(binary, dest)
    else:
        subprocess.run(
            ["lipo", "-thin", arch, "-output", str(dest), str(binary)], check=True
        )
    return True


def build_sim_framework(framework: Path, out_root: Path) -> bool:
    name = framework.stem
    binary = framework / name
    if not binary.is_file():
        return False

    staged = out_root / f"{name}.framework"
    shutil.rmtree(staged, ignore_errors=True)
    shutil.copytree(framework, staged, symlinks=True)

    work = out_root / f".{name}.work"
    shutil.rmtree(work, ignore_errors=True)
    work.mkdir(parents=True)

    # Every MLKit framework is staged so the simulator search path resolves, but
    # only slices that actually declare an iOS platform need retargeting. A few
    # carry no LC_BUILD_VERSION at all and link against either platform as-is.
    arm = work / "arm64"
    if slice_out(binary, "arm64", arm):
        blob = bytearray(arm.read_bytes())
        count = retarget_to_simulator(blob)
        arm.write_bytes(blob)

        x86 = work / "x86_64"
        if slice_out(binary, "x86_64", x86):
            subprocess.run(
                ["lipo", "-create", str(arm), str(x86), "-output", str(staged / name)],
                check=True,
            )
        else:
            shutil.copy2(arm, staged / name)
        print(f"  {name}: retargeted {count} arm64 objects")
    else:
        print(f"  {name}: no arm64 slice, staged unchanged")

    shutil.rmtree(work, ignore_errors=True)
    return True


def main() -> int:
    pods = Path(sys.argv[1] if len(sys.argv) > 1 else "Pods").resolve()
    if not pods.is_dir():
        print(f"error: {pods} is not a directory", file=sys.stderr)
        return 1

    built = 0
    for framework in sorted(pods.glob("ML*/Frameworks/*.framework")):
        out_root = framework.parent.parent / "Frameworks-sim"
        out_root.mkdir(exist_ok=True)
        if build_sim_framework(framework, out_root):
            built += 1

    if built == 0:
        print("error: no MLKit frameworks were patched", file=sys.stderr)
        return 1
    print(f"arm64-simulator variants ready for {built} MLKit frameworks")
    return 0


if __name__ == "__main__":
    sys.exit(main())
