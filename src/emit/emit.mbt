///|
let asm_start =
  #|format ELF64 executable
  #|segment readable executable
  #|entry _start
  #|_start:
  #|  call main
  #|  mov  rdi,rax
  #|  mov  rax,60
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
fn show_binop(binop : @asm.BinaryOp) -> String {
  match binop {
    Sub => "sub"
    Add => "add"
    Mul => "imul"
  }
}

///|
// let show_operand_size : (@asm.OperandSize) -> String = fn { 
//   DWord => "dword" 
// }

///|
fn show_operand_byte(operand : @asm.Operand) -> String {
  match operand {
    Imm(i) => i.to_string()
    Reg(AX) => "al"
    Reg(DX) => "dl"
    Reg(R10) => "r10b"
    Reg(R11) => "r11b"
    Stack(i) => "byte [rbp \{i}]"
    _ => @utils.die("unsupport operand")
  }
}

///|
fn show_operand_dw(operand : @asm.Operand) -> String {
  match operand {
    Imm(i) => i.to_string()
    Reg(AX) => "eax"
    Reg(DX) => "edx"
    Reg(R10) => "r10d"
    Reg(R11) => "r11d"
    Stack(i) => "dword [rbp \{i}]"
    _ => @utils.die("unsupport operand")
  }
  
}

///|
let show_cond_code : (@asm.CondCode) -> String = fn {
  E => "e"
  NE => "ne"
  L => "l"
  LE => "le"
  G => "g"
  GE => "ge"
}

///|
fn emit_instruction(inst : @asm.Instruction) -> String {
  let inst_str = match inst {
    Mov(dst~, src~) => "mov  \{show_operand_dw (dst)} , \{show_operand_dw(src)}"
    Ret =>
      #|mov  rsp,rbp
      #|  pop  rbp
      #|  ret
    Unary(op, operand) => "\{show_unop(op)}  \{show_operand_dw(operand)}"
    AllocateStack(i) => "sub  rsp,\{i}"
    Idiv(operand) => "idiv \{show_operand_dw(operand)}"
    Binary(binop, dst~, src~) =>
      "\{show_binop(binop)} \{show_operand_dw(dst)}, \{show_operand_dw(src)}"
    Cdq => "cdq"
    Jmp(label) => "jmp  .L\{label}"
    Cmp(arg1, arg2) => "cmp  \{show_operand_dw(arg1)}, \{show_operand_dw(arg2)}"
    JmpCC(cond_code, label) => "j\{show_cond_code(cond_code)} .L\{label}"
    SetCC(cond_code, operand) =>
      "set\{show_cond_code(cond_code)} \{show_operand_byte(operand)}"
    Label(label) => ".L\{label}:"
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
