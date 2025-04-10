///|
pub(all) struct Program {
  func : Function
} derive(Show)

///|
pub(all) struct Function {
  name : String
  body : Array[BlockItem]
} derive(Show)

///|
pub(all) enum BlockItem {
  S(Stmt)
  D(Decl)
} derive(Show)

///|
pub(all) enum Stmt {
  Return(Expr)
  Expression(Expr)
  Null
  If(cond~ : Expr, then_stmt~ : Stmt, else_stmt~ : Stmt?)
} derive(Show)

///|
pub(all) struct Decl {
  name : String
  init : Expr?
} derive(Show)

///|
pub(all) enum Expr {
  Constant(Int)
  Unary(UnaryOp, Expr)
  Binary(BinaryOp, Expr, Expr)
  Var(String)
  Assignment(Expr, Expr)
  Conditional(cond~:Expr,then_expr~:Expr,else_expr~:Expr)
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
