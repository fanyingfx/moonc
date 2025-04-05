///|
pub(all) struct Program {
  prog : Function
} derive(Show)

///|
pub(all) struct Function {
  name : String
  instructions : Array[Instruction]
} derive(Show)

///|
pub(all) enum Instruction {
  Mov(dst~ : Operand, src~ : Operand)
  Ret
} derive(Show)

///|
pub(all) enum Operand {
  Imm(Int)
  Register
} derive(Show)
