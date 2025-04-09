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

  fn parse_statement(token_stream : TokenStream) -> Stmt {
    match token_stream.peek() {
      KWReturn => {
        let _ = token_stream.take()
        let return_val = token_stream.parse_expr(0)
        token_stream.expect(Semicolon)
        return Return(return_val)
      }
      _=>{
        let expr = token_stream.parse_expr(0)
        token_stream.expect(Semicolon)
        Expression(expr)
      }
      // tok => @utils.die("Error Token: \{tok}")
    }
  }

  match self.peek() {
    KWInt => D(parse_decl(self))
    _ => S(parse_statement(self))
  }
}

///|
pub fn parse_expr(self : TokenStream, min_prec : Int) -> Expr {
  let mut left = self.parse_factor()
  let mut next_token = self.peek()
  while is_binop(next_token) && next_token.precdence() >= min_prec {
    if next_token is Equal {
      let _ = self.take()
      let right = self.parse_expr(next_token.precdence())
      left = Assignment(left, right)
      next_token=self.peek()
    } else {
      let op = self.parse_binop()
      let right = self.parse_expr(next_token.precdence() + 1)
      left = Binary(op, left, right)
      next_token = self.peek()
    }
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
  | GreaterOrEqual)
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
  let tokens  = @lexer.lex(func_str)
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
test "function" {
  let code =
    #|int main(void){
    #|  int b;
    #|  b = 2 *2;
    #|  return b;
    #|}
  inspect!(func(code), content=#|{func: {name: "main", body: [D({name: "b", init: None}), S(Expression(Assignment(Var("b"), Binary(Mul, Constant(2), Constant(2))))), S(Return(Var("b")))]}}
  )
}
