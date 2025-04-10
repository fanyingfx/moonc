#!/usr/bin/python

from pathlib import Path
import subprocess
example_path = Path("./examples")
def compile_with_ccompiler(filename:str)->str:
    cc = "clang"
    exe_name = filename.rstrip(".c")
    res = subprocess.run([cc,filename,"-o",exe_name])
    if res.returncode != 0:
        raise Exception(f"Compile with {cc} failed!")
    return exe_name
def compile_with_mooncompiler(filename:str)->str:
    subprocess.run(["moon","run","src/main","--",filename],check=True)
    asm_file = filename.replace(".c",".asm")
    subprocess.run(["fasm",asm_file], stdout=subprocess.DEVNULL,check=True)
    return asm_file.removesuffix(".asm")
for file in example_path.iterdir():
    if file.is_file() and file.name.endswith(".c"):
        cc_exe = compile_with_ccompiler(str(file))
        cc_res = subprocess.run([cc_exe])
        mcc_exe = compile_with_mooncompiler(str(file))
        mcc_res = subprocess.run([mcc_exe])
        assert(cc_res.returncode == mcc_res.returncode)
        print(f"{file} passed")

