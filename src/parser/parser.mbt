///|
typealias @lexer.Token

///|
pub type TokenStream @queue.T[Token] derive(Show)

///|
pub fn parse(tokens : @queue.T[Token]) -> Program {
  let token_stream : TokenStream = tokens
  let func = token_stream.parse_function_def()
  token_stream.expect(EOF)
  { func, }
}

///|
fn parse_function_def(self : TokenStream) -> Function {
  self.expect(KWInt)
  self.expect(Identifier("main"))
  self.expect(LParen)
  self.expect(KWVoid)
  self.expect(RParen)
  self.expect(LBrace)
  let body = []
  while self.peek() != RBrace {
    let next_block_item = self.parse_block_item()
    body.push(next_block_item)
  }
  let _ = self.take()
  return { name: "main", body }
}

///|
fn parse_block_item(self : TokenStream) -> BlockItem {
  match self.peek() {
    KWInt => D(parse_decl(self))
    _ => S(parse_statement(self))
  }
}

///|
fn parse_statement(self : TokenStream) -> Stmt {
  match self.peek() {
    KWReturn => {
      let _ = self.take()
      let return_val = self.parse_expr(0)
      self.expect(Semicolon)
      Return(return_val)
    }
    KWIf => {
      let _ = self.take()
      self.expect(LParen)
      let cond = self.parse_expr(0)
      self.expect(RParen)
      let thenStmt = self.parse_statement()
      let elseStmt = match self.peek() {
        KWElse => {
          let _ = self.take()
          Some(self.parse_statement())
        }
        _ => None
      }
      If(cond~, then_stmt=thenStmt, else_stmt=elseStmt)
    }
    _ => {
      let expr = self.parse_expr(0)
      self.expect(Semicolon)
      Expression(expr)
    }
  }
}

///|
fn parse_decl(token_stream : TokenStream) -> Decl {
  let _ = token_stream.take() // remove KWInt
  let name = token_stream.parse_ident()
  let mut init = None
  if token_stream.peek() == Equal {
    let _ = token_stream.take()
    init = Some(token_stream.parse_expr(0))
  }
  token_stream.expect(Semicolon)
  { name, init }
}

///|
pub fn parse_expr(self : TokenStream, min_prec : Int) -> Expr {
  let mut left = self.parse_factor()
  let mut next_token = self.peek()
  while is_binop(next_token) && next_token.precdence() >= min_prec {
    match next_token {
      Equal => {
        let _ = self.take()
        let right = self.parse_expr(next_token.precdence())
        left = Assignment(left, right)
      }
      QuestionMark => {
        let _ = self.take()
        let then_expr = self.parse_expr(0)
        self.expect(Colon)
        let else_expr = self.parse_expr(next_token.precdence())
        left = Conditional(cond=left, then_expr~, else_expr~)
      }
      _ => {
        let op = self.parse_binop()
        let right = self.parse_expr(next_token.precdence() + 1)
        left = Binary(op, left, right)
      }
    }
    next_token = self.peek()
  }
  left
}

///|
fn parse_factor(self : TokenStream) -> Expr {
  match self.peek() {
    Constant(i) => {
      let _ = self.take()
      Expr::Constant(i)
    }
    Tilde | Hyphen => {
      let op = self.parse_unaryop()
      let inner_expr = self.parse_factor()
      Unary(op, inner_expr)
    }
    LParen => {
      let _ = self.take()
      let inner_expr = self.parse_expr(0)
      self.expect(RParen)
      inner_expr
    }
    Identifier(name) => {
      let _ = self.take()
      Var(name)
    }
    tok => @utils.die("Malformed expression: \{tok}")
  }
}

///|
fn peek(self : TokenStream) -> Token {
  match self._.peek() {
    Some(tok) => tok
    _ => @utils.die("End of stream")
  }
}

///|
pub fn take(self : TokenStream) -> Token {
  match self._.pop() {
    Some(tok) => tok
    _ => @utils.die("End of stream")
  }
}

///|
fn parse_unaryop(self : TokenStream) -> UnaryOp {
  match self.take() {
    Hyphen => Negate
    Tilde => Complement
    errorToken => @utils.die("Wrong UnaryOp: \{errorToken}")
  }
}

///|
fn parse_binop(self : TokenStream) -> BinaryOp {
  match self.take() {
    Plus => Add
    Hyphen => Sub
    Star => Mul
    Slash => Div
    Percent => Rem
    LogicAnd => And
    LogicOr => Or
    DoubleEqual => Equal
    BangEqual => NotEqual
    LessThan => LessThan
    GreaterThan => GreaterThan
    LessOrEqual => LessOrEqual
    GreaterOrEqual => GreaterOrEqual
    errorToken => @utils.die("Wrong BinaryOp: \{errorToken}")
  }
}

///|
fn expect(self : TokenStream, expected : Token) -> Unit {
  let actual = self.take()
  if actual != expected {
    println("expected:\{expected}, acutal:\{actual}")
    @utils.die("Syntax error")
  }
}

///|
fn parse_ident(self : TokenStream) -> String {
  match self.take() {
    Identifier(name) => name
    ident => @utils.die("\{ident} is not a Identifier")
  }
}

///|
fn is_binop(token : Token) -> Bool {
  token
  is (Plus
  | Hyphen
  | Equal
  | Star
  | Slash
  | Percent
  | LogicAnd
  | LogicOr
  | DoubleEqual
  | BangEqual
  | LessThan
  | GreaterThan
  | LessOrEqual
  | GreaterOrEqual
  | QuestionMark)
}

///| convert String to expr, only can use in test
pub fn expr(expr_str : String) -> Expr {
  let tokens : TokenStream = @lexer.lex(expr_str)
  parse_expr(tokens, 0)
}

///| convert String to BlockItem, only can use in test
pub fn block(stmt_str : String) -> BlockItem {
  let tokens : TokenStream = @lexer.lex(stmt_str)
  tokens.parse_block_item()
}

///|
fn func(func_str : String) -> Program {
  let tokens = @lexer.lex(func_str)
  parse(tokens)
}

///|
test "test parse binary" {
  inspect!(expr("2>3"), content="Binary(GreaterThan, Constant(2), Constant(3))")
  inspect!(
    expr("2>=3"),
    content="Binary(GreaterOrEqual, Constant(2), Constant(3))",
  )
  inspect!(expr("2<3"), content="Binary(LessThan, Constant(2), Constant(3))")
  inspect!(
    expr("2<=3"),
    content="Binary(LessOrEqual, Constant(2), Constant(3))",
  )
  inspect!(expr("2==3"), content="Binary(Equal, Constant(2), Constant(3))")
  inspect!(expr("2!=3"), content="Binary(NotEqual, Constant(2), Constant(3))")
  inspect!(expr("2&&3"), content="Binary(And, Constant(2), Constant(3))")
  inspect!(expr("2||3"), content="Binary(Or, Constant(2), Constant(3))")
}

///|
test "arithmetic precdence" {
  inspect!(
    expr("2+3+4"),
    content="Binary(Add, Binary(Add, Constant(2), Constant(3)), Constant(4))",
  )
  inspect!(
    expr("2+3*4"),
    content="Binary(Add, Constant(2), Binary(Mul, Constant(3), Constant(4)))",
  )
  inspect!(
    expr("2*3+4"),
    content="Binary(Add, Binary(Mul, Constant(2), Constant(3)), Constant(4))",
  )
  inspect!(
    expr("(2+3)*4"),
    content="Binary(Mul, Binary(Add, Constant(2), Constant(3)), Constant(4))",
  )
  inspect!(
    expr("2+3-4"),
    content="Binary(Sub, Binary(Add, Constant(2), Constant(3)), Constant(4))",
  )
  inspect!(
    expr("2-3/4"),
    content="Binary(Sub, Constant(2), Binary(Div, Constant(3), Constant(4)))",
  )
  inspect!(
    expr("2*3/4"),
    content="Binary(Div, Binary(Mul, Constant(2), Constant(3)), Constant(4))",
  )
  inspect!(
    expr("2/3*4"),
    content="Binary(Mul, Binary(Div, Constant(2), Constant(3)), Constant(4))",
  )
}

///|
test "compare" {
  inspect!(
    expr("2<3<=4"),
    content="Binary(LessOrEqual, Binary(LessThan, Constant(2), Constant(3)), Constant(4))",
  )
  inspect!(
    expr("2<=3<4"),
    content="Binary(LessThan, Binary(LessOrEqual, Constant(2), Constant(3)), Constant(4))",
  )
  inspect!(
    expr("2>3>=4"),
    content="Binary(GreaterOrEqual, Binary(GreaterThan, Constant(2), Constant(3)), Constant(4))",
  )
  inspect!(
    expr("2>=3>4"),
    content="Binary(GreaterThan, Binary(GreaterOrEqual, Constant(2), Constant(3)), Constant(4))",
  )
  inspect!(
    expr("2>=3<4"),
    content="Binary(LessThan, Binary(GreaterOrEqual, Constant(2), Constant(3)), Constant(4))",
  )
  inspect!(
    expr("2<3>=4"),
    content="Binary(GreaterOrEqual, Binary(LessThan, Constant(2), Constant(3)), Constant(4))",
  )
  inspect!(
    expr("2<3==4"),
    content="Binary(Equal, Binary(LessThan, Constant(2), Constant(3)), Constant(4))",
  )
  inspect!(
    expr("2<3!=4"),
    content="Binary(NotEqual, Binary(LessThan, Constant(2), Constant(3)), Constant(4))",
  )
}

///|
test "Conditional" {
  inspect!(expr("2<3?4:5"), content="Conditional(cond=Binary(LessThan, Constant(2), Constant(3)), then_expr=Constant(4), else_expr=Constant(5))")
}

///|
test "decl" {
  inspect!(
    block("int a = 1;"),
    content=
      #|D({name: "a", init: Some(Constant(1))})
    ,
  )
  inspect!(
    block("int a;"),
    content=
      #|D({name: "a", init: None})
    ,
  )
  inspect!(
    block("int a = 2+3;"),
    content=
      #|D({name: "a", init: Some(Binary(Add, Constant(2), Constant(3)))})
    ,
  )
}

///|
test "if-else" {
  let stmt =
    #| if (a==3)
    #|  return a;
    #|else
    #|  b=8;
  inspect!(
    block(stmt),
    content=
      #|S(If(cond=Binary(Equal, Var("a"), Constant(3)), then_stmt=Return(Var("a")), else_stmt=Some(Expression(Assignment(Var("b"), Constant(8))))))

    ,
  )
  let stmt1 =
    #| if (a==3)
    #|  return a;
  inspect!(
    block(stmt1),
    content=
      #|S(If(cond=Binary(Equal, Var("a"), Constant(3)), then_stmt=Return(Var("a")), else_stmt=None))

    ,
  )
}

///|
test "panic unsupport block" {
  let stmt =
    #| if (a==3){
    #|  int b= 1;
    #|  retun b+a;
    #|}
  let _ = block(stmt)

}

///|
test "function" {
  let code =
    #|int main(void){
    #|  int b;
    #|  b = 2 *2;
    #|  return b;
    #|}
  inspect!(
    func(code),
    content=
      #|{func: {name: "main", body: [D({name: "b", init: None}), S(Expression(Assignment(Var("b"), Binary(Mul, Constant(2), Constant(2))))), S(Return(Var("b")))]}}
    ,
  )
}
