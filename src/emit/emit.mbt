///|
priv trait Show {
  str(Self) -> String
}
///|
priv trait ShowOperand {
  dword(Self) -> String
  byte(Self) -> String
}

///|
impl Show for @asm.UnaryOp with str(self) {
  match self {
    Neg => "neg"
    Not => "not"
  }
}

///|
impl Show for @asm.BinaryOp with str(self) {
  match self {
    Sub => "sub"
    Add => "add"
    Mul => "imul"
  }
}

///|
impl Show for @asm.CondCode with str(self) {
  match self {
    E => "e"
    NE => "ne"
    L => "l"
    LE => "le"
    G => "g"
    GE => "ge"
  }
}

///|
impl ShowOperand for @asm.Operand with dword(self) {
  match self {
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
impl ShowOperand for @asm.Operand with byte(self) {
  match self {
    Imm(i) => "\{i}"
    Reg(AX) => "al"
    Reg(DX) => "dl"
    Reg(R10) => "r10b"
    Reg(R11) => "r11b"
    Stack(i) => "byte [rbp \{i}]"
    _ => @utils.die("unsupport operand")
  }
}


///|
fn emit_instruction(inst : @asm.Instruction) -> String {
  let inst_str = match inst {
    Mov(dst~, src~) => "mov  \{dst.dword()} , \{src.dword()}"
    Ret =>
      #|mov  rsp,rbp
      #|  pop  rbp
      #|  ret
    Unary(op, operand) => "\{op.str()}  \{operand.dword()}"
    AllocateStack(i) => "sub  rsp,\{i}"
    Idiv(operand) => "idiv \{operand.dword()}"
    Binary(binop, dst~, src~) => "\{binop.str()} \{dst.dword()}, \{src.dword()}"
    Cdq => "cdq"
    Jmp(label) => "jmp  .L\{label}"
    Cmp(arg1, arg2) => "cmp  \{arg1.dword()}, \{arg2.dword()}"
    JmpCC(cond_code, label) => "j\{cond_code.str()} .L\{label}"
    SetCC(cond_code, operand) =>
      "set\{cond_code.str()} \{operand.byte()}"
    Label(label) => ".L\{label}:"
  }
  return inst_str + "\n"
}

///|
fn emit_func(func : @asm.Function) -> String {
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
let start_main =
  #|format ELF64 executable
  #|segment readable executable
  #|entry _start
  #|_start:
  #|  call main
  #|  mov  rdi,rax
  #|  mov  rax,60
  #|  syscall

///|
pub fn emit(filename : String, func_def : @asm.Program) -> Unit {
  let func_asm = emit_func(func_def.func)
  let asm = match func_def.func.name {
    "main" => "\{start_main}\n\{func_asm}"
    _ => func_asm
  }
  @fs.write_string_to_file?(filename, asm).unwrap()
}
