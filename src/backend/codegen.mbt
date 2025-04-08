// 1. convert TACKY to Assembly
///|
fn convert_unop(op : @tacky.UnaryOp) -> @asm.UnaryOp {
  match op {
    Complement => Not
    Negate => Neg
    Not => @utils.die("Can't convert tacky Not to asm")
  }
}

///|
fn convert_binop(op : @tacky.BinaryOp) -> @asm.BinaryOp {
  match op {
    Mul => Mul
    Sub => Sub
    Add => Add
    _ => @utils.die("Div/Rem should be converted")
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
let to_cond_code : (@tacky.BinaryOp) -> @asm.CondCode = fn {
  Equal => E
  NotEqual => NE
  GreaterThan => G
  GreaterOrEqual => GE
  LessThan => L
  LessOrEqual => LE
  op => @utils.die("\{op} can't convert to cond code")
}

///|
fn convert_instruction(instr : @tacky.Instruction) -> Array[@asm.Instruction] {
  match instr {
    Return(val) => [Mov(dst=Reg(AX), src=convert_val(val)), Ret]
    Unary(op, dst~, src~) => {
      let dst = convert_val(dst)
      let src = convert_val(src)
      if op is Not {
        [Cmp(src, Imm(0)), Mov(dst~, src=Imm(0)), SetCC(E, dst)]
      } else {
        [Mov(dst~, src~), Unary(convert_unop(op), dst)]
      }
    }
    Binary(op, dst~, src1~, src2~) => {
      let src1 = convert_val(src1)
      let src2 = convert_val(src2)
      let dst = convert_val(dst)
      match op {
        Add | Sub | Mul =>
          [Mov(dst~, src=src1), Binary(convert_binop(op), dst~, src=src2)]
        Div =>
          [Mov(dst=Reg(AX), src=src1), Cdq, Idiv(src2), Mov(dst~, src=Reg(AX))]
        Rem =>
          [Mov(dst=Reg(AX), src=src1), Cdq, Idiv(src2), Mov(dst~, src=Reg(DX))]
        Equal
        | NotEqual
        | GreaterThan
        | GreaterOrEqual
        | LessThan
        | LessOrEqual =>
          [Cmp(src1, src2), Mov(dst~, src=Imm(0)), SetCC(to_cond_code(op), dst)]
      }
    }
    JumpIfZero(val, target) => [Cmp(convert_val(val), Imm(0)), JmpCC(E, target)]
    Jump(target) => [Jmp(target)]
    Copy(dst~, src~) => [Mov(dst=convert_val(dst), src=convert_val(src))]
    JumpIfNotZero(val, target) =>
      [Cmp(convert_val(val), Imm(0)), JmpCC(NE, target)]
    Label(target) => [Label(target)]
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
