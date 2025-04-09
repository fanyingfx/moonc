///|
typealias @parser.(Expr, Stmt)

///|
pub fn gen_tacky(prog : @parser.Program) -> Program {
  { func: emit_func_decl(prog.func) }
}

///|
fn emit_func_decl(func : @parser.Function) -> Function {
  let instructions = []
  for block in func.body {
    instructions.append(emit_block(block))
  }
  // NOTE Add return 0 at the end,for function without return val
  // will remove after optimaztion.
  instructions.push(Return(Constant(0)))
  { name: func.name, instructions }
}

///|
fn emit_block(block : @parser.BlockItem) -> Array[Instruction] {
  match block {
    S(stmt) => emit_stmt(stmt)
    D(decl) => emit_decl(decl)
  }
}

///|
fn emit_decl(decl : @parser.Decl) -> Array[Instruction] {
  match decl.init{
    None => []
    Some(expr) => {
      let (instructions,result)=emit_expr(expr)
      instructions.push(Copy(dst=Var(decl.name),src=result))
      instructions
    }

  }

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
    Expression(expr) => {
      let (instrs, _) = emit_expr(expr)
      instrs
    }
    Null => []
  }
}

///|
fn emit_expr(expr : Expr) -> (Array[Instruction], Val) {
  match expr {
    Expr::Constant(c) => ([], Constant(c))
    Expr::Unary(op, inner) => emit_unary(op, inner)
    Expr::Binary(And, e1, e2) => emit_and_expr(e1, e2)
    Expr::Binary(Or, e1, e2) => emit_or_expr(e1, e2)
    Expr::Binary(op, e1, e2) => emit_binary(op, e1, e2)
    Expr::Var(v) => ([], Var(v))
    Assignment(Var(v), rhs) => {
      let (instructions, result) = emit_expr(rhs)
      instructions.push(Copy(dst=Var(v), src=result))
      (instructions, Var(v))
    }
    Assignment(_) => @utils.die("Only Var can be assigned")
  }
}
///|

///|

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
  @utils.reset_counter()
  let expr = @parser.expr(expr_str)
  let (instrs, v) = emit_expr(expr)
  instrs.push(Return(v))
  instrs
}
fn func(func_str:String)->Program{
  @utils.reset_counter()
  let tokens = @lexer.lex(func_str)
  let ast = @parser.parse(tokens)
  let validated_ast = @semantic_analysis.validate(ast)
  let tacky = gen_tacky(validated_ast)
  tacky
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
      #|[Binary(LessThan, dst=Var("tmp.0"), src1=Constant(2), src2=Constant(3)), JumpIfZero(Var("tmp.0"), "false_2"), Binary(GreaterThan, dst=Var("tmp.1"), src1=Constant(5), src2=Constant(10)), JumpIfZero(Var("tmp.1"), "false_2"), Copy(dst=Var("tmp.4"), src=Constant(1)), Jump("end_3"), Label("false_2"), Copy(dst=Var("tmp.4"), src=Constant(0)), Label("end_3"), Return(Var("tmp.4"))]

    ,
  )
}
test "basic function"{
  let code = 
  #|int main(void){
  #|  int b;
  #|  int a = 10 + 1 ;
  #|  b = a *2;
  #|  return b;
  #|}
  
  inspect!(func(code), content=
    #|{func: {name: "main", instructions: [Binary(Add, dst=Var("tmp.2"), src1=Constant(10), src2=Constant(1)), Copy(dst=Var("a"), src=Var("tmp.2")), Binary(Mul, dst=Var("tmp.3"), src1=Var("tmp.1"), src2=Constant(2)), Copy(dst=Var("tmp.0"), src=Var("tmp.3")), Return(Var("tmp.0")), Return(Constant(0))]}}


  )
  
}
