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
  #|

///|
fn show_unop(unop : @asm.UnaryOp) -> String {
  match unop {
    Neg => "neg"
    Not => "not"
  }
}

///|
fn show_operand(operand : @asm.Operand) -> String {
  match operand {
    Imm(i) => i.to_string()
    Reg(AX) => "eax"
    Reg(R10) => "r10d"
    Stack(i, DWord) => "dword [rbp \{i}]" // TODO 如何判断是否是dword
    _ => @utils.die("unsupport operand")
  }
}

///|
fn emit_instruction(inst : @asm.Instruction) -> String {
  let inst_str = match inst {
    Mov(dst~, src~) => "mov \{show_operand (dst)} , \{show_operand(src)}"
    Ret =>
      #|mov rsp,rbp
      #|  pop rbp
      #|  ret
    Unary(op, operand) => "\{show_unop(op)} \{show_operand(operand)}"
    AllocateStack(i) => "sub rsp,\{i}"
  }
  return inst_str + "\n"
}

///|
fn emit_toplevel(func : @asm.Function) -> String {
  let label = func.name
  let instructions = func.instructions.map(fn(instr) {
    "  " + emit_instruction(instr)
  })
  $|\{label}:
  #|  push rbp
  #|  mov  rbp, rsp
  $|\{@string.concat(instructions)}
}

///|
pub fn emit(filename : String, func_def : @asm.Program) -> Unit {
  let content = asm_start + "\n" + emit_toplevel(func_def.func)
  @fs.write_string_to_file?(filename, content).unwrap()
}
