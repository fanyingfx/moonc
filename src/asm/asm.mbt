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
  AllocateStack(Int)
  Ret
} derive(Show)

///|
pub(all) enum UnaryOp {
  Neg
  Not
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
  R10
} derive(Show)
