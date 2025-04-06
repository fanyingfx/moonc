// 1. convert TACKY to Assembly
///|
fn convert_unop(op : @tacky.UnaryOp) -> @asm.UnaryOp {
  match op {
    Complement => Not
    Negate => Neg
  }
}

///|
fn convert_val(val : @tacky.Val) -> @asm.Operand {
  match val {
    Constant(i) => Imm(i)
    Var(name) => Pseudo(name)
  }
}

///|
fn convert_instruction(instr : @tacky.Instruction) -> Array[@asm.Instruction] {
  match instr {
    Return(val) => [Mov(dst=Reg(AX), src=convert_val(val)), Ret]
    Unary(op, dst~, src~) => {
      let dst = convert_val(dst)
      let src = convert_val(src)
      [Mov(dst~, src~), Unary(convert_unop(op), dst)]
    }
  }
}

///|
fn convert_func(func : @tacky.Function) -> @asm.Function {
  {
    name: func.name,
    instructions: func.instructions.map(convert_instruction).flatten(),
  }
}

///|
pub fn convert_program(prog : @tacky.Program) -> @asm.Program {
  { func: convert_func(prog.func) }
}
