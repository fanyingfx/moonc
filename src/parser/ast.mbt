///|
enum Expr {
  Constant(Int)
  Var(String)
} derive(Show)

///|
enum Stmt {
  Return(Expr)
  If(cond~ : Expr, thenStmt~ : Stmt, elseStmt~ : Stmt?)
} derive(Show)

///|
struct Function {
  name : String
  body : Stmt
} derive(Show)

///|
struct Program {
  prog : Function
} derive(Show)
