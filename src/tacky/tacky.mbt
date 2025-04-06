///|
pub(all) struct Program {
  func : Function
} derive(Show, Eq)

///|
pub(all) struct Function {
  name : String
  instructions : Array[Instruction]
} derive(Show, Eq)

///|
pub(all) enum Instruction {
  Return(Val)
  Unary(UnaryOp, dst~ : Val, src~ : Val)
  Binary(BinaryOp, dst~ : Val, src1~ : Val, src2~ : Val)
} derive(Show, Eq)

///|
pub(all) enum Val {
  Constant(Int)
  Var(String)
} derive(Show, Eq)

///|
pub(all) enum UnaryOp {
  Complement
  Negate
} derive(Show, Eq)

///|
pub(all) enum BinaryOp {
  Add
  Sub
  Mul
  Div
  Rem
} derive(Show, Eq)
