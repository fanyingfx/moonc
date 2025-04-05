///|
let asm_start =
  #|format ELF64 executable
  #|segment readable executable
  #|entry _start
  #|_start:
  #|  call main
  #|  mov rdi,rax
  #|  mov rax,60
  #|  syscall

///|
fn show_operand(operand : @asm.Operand) -> String {
  match operand {
    Imm(i) => i.to_string()
    Register => "eax"
  }
}

///|
fn emit_instruction(inst : @asm.Instruction) -> String {
  let inst_str = match inst {
    Mov(dst~, src~) => "mov \{show_operand (dst)} , \{show_operand(src)}"
    Ret =>
      #|  mov  rsp,rbp
      #|  pop  rbp
      #|  ret
  }
  return inst_str + "\n"
}

///|
fn emit_tl(func : @asm.Function) -> String {
  let label = func.name
  let instructions = func.instructions.map(emit_instruction)
  $|\{label}:
  #|  push  rbp
  #|  mov   rbp, rsp
  $|  \{@string.concat(instructions)}
}

///|
pub fn emit(filename : String, func_def : @asm.Program) -> Unit {
  let content = asm_start + "\n" + emit_tl(func_def.prog)
  @fs.write_string_to_file?(filename, content).unwrap()
}
