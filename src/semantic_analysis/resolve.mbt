// let variable_map:Map[String,String]={}
///|
typealias @parser.(Expr, Stmt, Decl)

///|
priv type VariableMap Map[String, String]

///|
pub fn validate(prog : @parser.Program) -> @parser.Program {
  { func: resolve_func(prog.func) }
}

///|O
/// 
fn resolve_func(func : @parser.Function) -> @parser.Function {
  let variable_map : VariableMap = {}
  let body : Array[@parser.BlockItem] = []
  let resolve_blockitem : (@parser.BlockItem) -> @parser.BlockItem = fn {
    S(stmt) => S(variable_map.resolve_stmt(stmt))
    D(decl) => D(variable_map.resolve_decl(decl))
  }
  for block in func.body {
    body.push(resolve_blockitem(block))
  }
  { name: func.name, body }
}

///|
fn resolve_decl(self : VariableMap, decl : Decl) -> Decl {
  if self._.contains(decl.name) {
    @utils.die("Duplicate variable declaration!")
  }
  let unique_name = @utils.make_temporary()
  self._.set(decl.name, unique_name)
  let init = match decl.init {
    None => None
    Some(init) => Some(self.resolve_expr(init))
  }
  { name: decl.name, init }
}

///|
fn resolve_stmt(self : VariableMap, stmt : Stmt) -> Stmt {
  match stmt {
    Null => Null
    Expression(e) => Expression(self.resolve_expr(e))
    Return(e) => Return(self.resolve_expr(e))
    If(cond~, then_stmt~, else_stmt~) => {
      let cond = self.resolve_expr(cond)
      let then_stmt = self.resolve_stmt(then_stmt)
      let else_stmt = match else_stmt {
        Some(stmt) => Some(self.resolve_stmt(stmt))
        None => None
      }
      If(cond~, then_stmt~, else_stmt~)
    }
  }
}

///|
fn resolve_expr(self : VariableMap, expr : Expr) -> Expr {
  match expr {
    Assignment(left, right) => {
      if not(left is Var(_)) {
        @utils.die("Invalid lValue!")
      }
      Assignment(self.resolve_expr(left), self.resolve_expr(right))
    }
    Var(name) =>
      match self._[name] {
        Some(name) => Var(name)
        None => @utils.die("Undeclared variable")
      }
    Binary(op, left, right) =>
      Binary(op, self.resolve_expr(left), self.resolve_expr(right))
    Unary(op, expr) => Unary(op, self.resolve_expr(expr))
    Constant(i) => Constant(i)
    Conditional(cond~, then_expr~, else_expr~) => {
      let cond = self.resolve_expr(cond)
      let then_expr = self.resolve_expr(then_expr)
      let else_expr = self.resolve_expr(else_expr)
      Conditional(cond~, then_expr~, else_expr~)
    }
  }
}

///|
test "validate basic" {
  @utils.reset_counter()
  let code =
    #|int main (void){
    #|  int a = 1;
    #|  int b = a+1;
    #|  return a+b;
    #|}
  let tokens = @lexer.lex(code)
  let program_ast = @parser.parse(tokens)
  let validated_ast = validate(program_ast)
  inspect!(
    validated_ast,
    content=
      #|{func: {name: "main", body: [D({name: "a", init: Some(Constant(1))}), D({name: "b", init: Some(Binary(Add, Var("tmp.0"), Constant(1)))}), S(Return(Binary(Add, Var("tmp.0"), Var("tmp.1"))))]}}
    ,
  )
}
