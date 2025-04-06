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
