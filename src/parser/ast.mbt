///|
pub(all) enum Expr {
  Constant(Int)
  Unary(UnaryOp, Expr)
  Binary(BinaryOp, Expr, Expr)
  Var(String)
  Assignment(Expr, Expr)
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
  Expression(Expr)
  Null
  If(cond~ : Expr, thenStmt~ : Stmt, elseStmt~ : Stmt?)
} derive(Show)

///|
pub(all) struct Decl {
  name : String
  init : Expr?
}derive(Show)

pub(all) enum BlockItem{
  S(Stmt)
  D(Decl)
}derive(Show)

///|
pub(all) struct Function {
  name : String
  body : Array[BlockItem]
} derive(Show)

///|
pub(all) struct Program {
  func : Function
} derive(Show)
