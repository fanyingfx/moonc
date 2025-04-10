#!/usr/bin/env python3

import shutil
import subprocess
from collections.abc import Callable
from pathlib import Path

BASIC_TESTS = Path("./tests/basic")
BUILD_DIR = Path("./tests/build/")
RED = "\033[31m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
BLUE = "\033[34m"
RESET = "\033[0m"


def setup_build_directory(build_path: Path) -> None:
    """Set build folder, and cleanup"""
    if build_path.exists():
        if build_path.is_file():
            build_path.unlink()
        else:
            shutil.rmtree(build_path)
    build_path.mkdir()


def cc_compile(cfile: Path) -> str:
    """Compile with production c compiler, current is clang"""
    cc = "clang"
    exe_name = str(cfile.with_suffix("")) + "_cc"
    subprocess.run([cc, str(cfile), "-o", exe_name], check=True)
    return exe_name


def mooncc_compile(cfile: Path) -> str:
    """Compile with mooncc"""
    basename = str(cfile.with_suffix(""))
    asmfile = Path(basename + ".asm")

    new_exe_name = basename + "_mcc"
    subprocess.run(["moon", "run", "src/main", "--", str(cfile)], check=True)
    subprocess.run(["fasm", str(asmfile)], stdout=subprocess.DEVNULL, check=True)

    shutil.move(asmfile, BUILD_DIR)
    Path(basename).rename(new_exe_name)
    return str(new_exe_name)


def count_cfiles(folder: Path) -> int:
    total_count = 0
    for file in folder.iterdir():
        if file.is_file() and file.name.endswith(".c"):
            total_count += 1
    return total_count


def compile_and_run(compile_func: Callable[[Path], str], file) -> int:
    exe = compile_func(file)
    res = subprocess.run([exe])
    shutil.move(exe, BUILD_DIR)
    return res.returncode

def failed_case(folder:Path):
    print(f"Start testing in {BLUE}{folder}{RESET}")
    total_count = count_cfiles(folder)
    curr_count = 0
    for file in folder.iterdir():
        if file.is_file() and file.name.endswith(".c"):
            curr_count += 1
            res = subprocess.run(["moon", "run", "src/main", "--", str(file)],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
            if res.returncode == 0:
                print(f"{RED}{file}{RESET} not passed")
                continue
            print(f"{GREEN}{file.stem:<20} passed{RESET} {curr_count}/{total_count}")

    print(f"End testing in {BLUE}{folder}{RESET}")


def test_case(folder: Path):
    print(f"Start testing in {BLUE}{folder}{RESET}")
    total_count = count_cfiles(folder)
    curr_count = 0
    for file in folder.iterdir():
        if file.is_file() and file.name.endswith(".c"):
            curr_count += 1
            cc_code = compile_and_run(cc_compile, file)
            mcc_code = compile_and_run(mooncc_compile, file)
            if cc_code != mcc_code:
                print(f"{RED}{file}{RESET} not passed, {cc_code=}, {mcc_code=}")
                continue
            print(f"{GREEN}{file.stem:<20} passed{RESET} {curr_count}/{total_count}")
    print(f"End testing in {BLUE}{folder}{RESET}")


def main():
    setup_build_directory(BUILD_DIR)
    test_case(BASIC_TESTS)
    # failed_case(BASIC_TESTS)


if __name__ == "__main__":
    main()
