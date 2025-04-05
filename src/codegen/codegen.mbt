///|
fn convert_exp(expr : @parser.Expr) -> @asm.Operand {
  match expr {
    Constant(i) => Imm(i)
    _ => @utils.die("not support yet")
  }
}

///|
fn convert_statement(stmt : @parser.Stmt) -> Array[@asm.Instruction] {
  match stmt {
    Return(e) => {
      let v = convert_exp(e)
      return [Mov(dst=Register, src=v), Ret]
    }
    If(_) => @utils.die("If not support yet")
  }
}

///|
fn convert_function(func : @parser.Function) -> @asm.Function {
  { name: func.name, instructions: convert_statement(func.body) }
}

///|
pub fn gen_asm(fn_def : @parser.Program) -> @asm.Program {
  { prog: convert_function(fn_def.prog) }
}
