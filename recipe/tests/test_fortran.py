"""Tests that the MED Fortran API works correctly.

Compiles and runs Fortran test programs that exercise the key MED
Fortran subroutines used by code-aster:
  - File operations: mfiope, mficlo, mficow, mficor, mlbnuv
  - Mesh operations: mmhcre, mmhcow, mmhcyw, mmhnmh, mmhmii, mmhcor
  - Field operations: mfdcre, mfdrvw, mfdrvr, mfdnfd, mfdnfc
"""

import os
import pathlib
import shutil
import subprocess
import sys

import pytest

FORTRAN_DIR = pathlib.Path(__file__).parent / "fortran"
FORTRAN_TESTS = ["test_file_ops", "test_mesh", "test_field"]


@pytest.fixture(scope="session")
def fortran_build_dir(tmp_path_factory):
    """Configure and build all Fortran test programs once per session."""
    build_dir = tmp_path_factory.mktemp("fortran_build")

    # Collect CMAKE_ARGS from the conda environment (set by compiler activation)
    cmake_args = []
    env_cmake_args = os.environ.get("CMAKE_ARGS", "")
    if env_cmake_args:
        cmake_args = env_cmake_args.split()

    # Default to Ninja when available (required for IFX on Windows,
    # avoids needing 'make' in test requirements on Linux)
    has_generator = any(a.startswith("-G") for a in cmake_args)
    if not has_generator and shutil.which("ninja"):
        cmake_args.extend(["-G", "Ninja"])

    # Configure
    cmd = ["cmake", str(FORTRAN_DIR)] + cmake_args
    result = subprocess.run(
        cmd, cwd=str(build_dir), capture_output=True, text=True
    )
    assert result.returncode == 0, (
        f"CMake configure failed:\n"
        f"command: {' '.join(cmd)}\n"
        f"stdout:\n{result.stdout}\n"
        f"stderr:\n{result.stderr}"
    )

    # Build
    result = subprocess.run(
        ["cmake", "--build", "."],
        cwd=str(build_dir),
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, (
        f"CMake build failed:\n"
        f"stdout:\n{result.stdout}\n"
        f"stderr:\n{result.stderr}"
    )

    return build_dir


@pytest.mark.parametrize("test_name", FORTRAN_TESTS)
def test_fortran(fortran_build_dir, test_name, tmp_path):
    """Run a compiled Fortran test and verify it passes."""
    ext = ".exe" if sys.platform == "win32" else ""
    exe = fortran_build_dir / f"{test_name}{ext}"

    assert exe.exists(), f"Test executable not found: {exe}"

    # Run in tmp_path so each test creates .med files in isolation
    result = subprocess.run(
        [str(exe)],
        cwd=str(tmp_path),
        capture_output=True,
        text=True,
        timeout=120,
    )

    # Print output for debugging regardless of result
    if result.stdout:
        print(result.stdout)
    if result.stderr:
        print(result.stderr, file=sys.stderr)

    assert result.returncode == 0, (
        f"Fortran test '{test_name}' failed (rc={result.returncode})"
    )
