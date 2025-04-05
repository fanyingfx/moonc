///|
pub enum Expr {
  Constant(Int)
  Var(String)
} derive(Show)

///|
pub enum Stmt {
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
  prog : Function
} derive(Show)
