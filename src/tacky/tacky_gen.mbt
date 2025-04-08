///|
typealias @parser.(Expr, Stmt)

///|
fn convert_unop(unop : @parser.UnaryOp) -> UnaryOp {
  match unop {
    Complement => Complement
    Negate => Negate
    Not => Not
  }
}

///|
fn convert_binop(binop : @parser.BinaryOp) -> BinaryOp {
  match binop {
    Add => Add
    Sub => Sub
    Mul => Mul
    Div => Div
    Rem => Rem
    NotEqual => NotEqual
    Equal => Equal
    LessThan => LessThan
    GreaterThan => GreaterThan
    LessOrEqual => LessOrEqual
    GreaterOrEqual => GreaterOrEqual
    _ => @utils.die("\{binop} should not be converted")
  }
}

///|

///|
fn emit_expr(expr : Expr) -> (Array[Instruction], Val) {
  match expr {
    Expr::Constant(c) => ([], Constant(c))
    Expr::Unary(op, inner) => emit_unary(op, inner)
    Expr::Binary(And, e1, e2) => emit_and_expr(e1, e2)
    Expr::Binary(Or, e1, e2) => emit_or_expr(e1, e2)
    Expr::Binary(op, e1, e2) => emit_binary(op, e1, e2)
    Expr::Var(_) => panic()
  }
}

///|
fn emit_binary(
  op : @parser.BinaryOp,
  e1 : Expr,
  e2 : Expr
) -> (Array[Instruction], Val) {
  let (instrs, v1) = emit_expr(e1)
  let (instrs2, v2) = emit_expr(e2)
  instrs.append(instrs2)
  let dst_name = @utils.make_temporary()
  let dst = Var(dst_name)
  let tacky_op = convert_binop(op)
  instrs.push(Binary(tacky_op, dst~, src1=v1, src2=v2))
  (instrs, dst)
}

///|
fn emit_and_expr(e1 : Expr, e2 : Expr) -> (Array[Instruction], Val) {
  let (instrs, v1) = emit_expr(e1)
  let (instrs2, v2) = emit_expr(e2)
  let false_label = @utils.make_label("false")
  let end_label = @utils.make_label("end")
  let dst_name = @utils.make_temporary()
  let dst = Var(dst_name)
  let _ = instrs
    ..push(JumpIfZero(v1, false_label))
    ..append(instrs2)
    ..append([
      JumpIfZero(v2, false_label),
      Copy(dst~, src=Constant(1)),
      Jump(end_label),
      Label(false_label),
      Copy(dst~, src=Constant(0)),
      Label(end_label),
    ])
  (instrs, dst)
}

///|
fn emit_or_expr(e1 : Expr, e2 : Expr) -> (Array[Instruction], Val) {
  let (instrs, v1) = emit_expr(e1)
  let (instrs2, v2) = emit_expr(e2)
  let true_label = @utils.make_label("true")
  let end_label = @utils.make_label("end")
  let dst_name = @utils.make_temporary()
  let dst = Var(dst_name)
  let _ = instrs
    ..push(JumpIfNotZero(v1, true_label))
    ..append(instrs2)
    ..append([
      JumpIfNotZero(v2, true_label),
      Copy(dst~, src=Constant(0)),
      Jump(end_label),
      Label(true_label),
      Copy(dst~, src=Constant(1)),
      Label(end_label),
    ])
  (instrs, dst)
}

///|
fn emit_unary(op : @parser.UnaryOp, inner : Expr) -> (Array[Instruction], Val) {
  let (instructions, src) = emit_expr(inner)
  let dst_name = @utils.make_temporary()
  let dst = Var(dst_name)
  let tacky_op = convert_unop(op)
  instructions.push(Unary(tacky_op, dst~, src~))
  return (instructions, dst)
}

///|
fn emit_stmt(stmt : Stmt) -> Array[Instruction] {
  match stmt {
    Return(exp) => {
      let (instrs, v) = emit_expr(exp)
      instrs.push(Return(v))
      instrs
    }
    If(_) => panic()
  }
}

///|
fn emit_func_decl(func : @parser.Function) -> Function {
  let instructions = emit_stmt(func.body)
  { name: func.name, instructions }
}

///|
pub fn gen_tacky(prog : @parser.Program) -> Program {
  { func: emit_func_decl(prog.func) }
}

///| test emit_expr and emit_statement
test {
  let expr = Expr::Unary(Negate, Constant(2))
  let stmt = @parser.Stmt::Return(expr)
  let instrs = emit_stmt(stmt)
  assert_eq!(instrs, [
    Unary(Negate, dst=Var("tmp.0"), src=Constant(2)),
    Return(Var("tmp.0")),
  ])
}

///|
fn expr(expr_str : String) -> Array[Instruction] {
  @utils.reset()
  let expr = @parser.expr(expr_str)
  let (instrs, v) = emit_expr(expr)
  instrs.push(Return(v))
  instrs
}

///|
test {
  inspect!(
    expr("2>3"),
    content=
      #|[Binary(GreaterThan, dst=Var("tmp.0"), src1=Constant(2), src2=Constant(3)), Return(Var("tmp.0"))]
    ,
  )
  inspect!(
    expr("2<3 && 5>10"),
    content=
      #|[Binary(LessThan, dst=Var("tmp.0"), src1=Constant(2), src2=Constant(3)), JumpIfZero(Var("tmp.0"), "false_0"), Binary(GreaterThan, dst=Var("tmp.1"), src1=Constant(5), src2=Constant(10)), JumpIfZero(Var("tmp.1"), "false_0"), Copy(dst=Var("tmp.2"), src=Constant(1)), Jump("end_1"), Label("false_0"), Copy(dst=Var("tmp.2"), src=Constant(0)), Label("end_1"), Return(Var("tmp.2"))]
    ,
  )
}
