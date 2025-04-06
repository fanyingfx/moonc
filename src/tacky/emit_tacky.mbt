///|
typealias @parser.(Expr, Stmt)

///|
fn convert_unop(unop : @parser.UnaryOp) -> UnaryOp {
  match unop {
    Complement => Complement
    Negate => Negate
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
  }
}

///|

///|
fn emit_expr(expr : Expr) -> (Array[Instruction], Val) {
  match expr {
    Expr::Constant(c) => ([], Constant(c))
    Expr::Unary(op, inner) => emit_unary(op, inner)
    Expr::Binary(op, e1, e2) => {
      let (instrs1, v1) = emit_expr(e1)
      let (instrs2, v2) = emit_expr(e2)
      instrs1.append(instrs2)
      let dst_name = @utils.make_temporary()
      let dst = Var(dst_name)
      let tacky_op = convert_binop(op)
      instrs1.push(Binary(tacky_op, dst~, src1=v1, src2=v2))
      (instrs1, dst)
    }
    Expr::Var(_) => panic()
  }
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
