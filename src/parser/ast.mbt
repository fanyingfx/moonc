///|
pub(all) enum Expr {
  Constant(Int)
  Unary(UnaryOp, Expr)
  Binary(BinaryOp, Expr, Expr)
  Var(String)
} derive(Show)

///|
pub(all) enum UnaryOp {
  Complement
  Negate
  Not
} derive(Show)

///|
pub(all) enum BinaryOp {
  // arithmetic
  Add
  Sub
  Mul
  Div
  Rem
  // Compare
  Equal
  NotEqual
  LessThan
  LessOrEqual
  GreaterThan
  GreaterOrEqual
  // logic
  And
  Or
} derive(Show)

///|
pub(all) enum Stmt {
  Return(Expr)
  If(cond~ : Expr, thenStmt~ : Stmt, elseStmt~ : Stmt?)
} derive(Show)

///|
pub struct Function {
  name : String
  body : Stmt
} derive(Show)

///|
pub struct Program {
  func : Function
} derive(Show)
