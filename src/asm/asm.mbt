///|
pub(all) struct Program {
  func : Function
} derive(Show)

///|
pub(all) struct Function {
  name : String
  instructions : Array[Instruction]
} derive(Show)

///|
pub(all) enum Instruction {
  Mov(dst~ : Operand, src~ : Operand)
  Unary(UnaryOp, Operand)
  Binary(BinaryOp, dst~ : Operand, src~ : Operand)
  Cmp(Operand, Operand)
  Idiv(Operand)
  Cdq
  Jmp(String)
  JmpCC(CondCode, String)
  SetCC(CondCode, Operand)
  Label(String)
  AllocateStack(Int)
  Ret
} derive(Show)

///|
pub(all) enum UnaryOp {
  Neg
  Not
} derive(Show)

///|
pub(all) enum BinaryOp {
  Add
  Sub
  Mul
} derive(Show)

///|
pub(all) enum Operand {
  Imm(Int)
  Reg(Register)
  Pseudo(String)
  Stack(Int)
} derive(Show)


///|
pub(all) enum Register {
  AX
  DX
  R10
  R11
} derive(Show)

///|
pub(all) enum CondCode {
  E
  NE
  G
  GE
  L
  LE
}derive(Show)
