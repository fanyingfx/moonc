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
  Copy(dst~:Val,src~:Val)
  Jump(String)
  JumpIfZero(Val,String)
  JumpIfNotZero(Val,String)
  Label(String)
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
  Not
} derive(Show, Eq)

///|
pub(all) enum BinaryOp {
  Add
  Sub
  Mul
  Div
  Rem
  Equal
  NotEqual
  LessThan
  LessOrEqual
  GreaterThan
  GreaterOrEqual
} derive(Show, Eq)
