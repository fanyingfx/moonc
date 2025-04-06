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
} derive(Show)

///|
pub(all) enum BinaryOp {
  Add
  Sub
  Mul
  Div
  Rem
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
