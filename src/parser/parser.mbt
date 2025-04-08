///|
typealias @lexer.Token

///|
pub type TokenStream @queue.T[Token] derive(Show)

///|
pub fn parse(tokens : @queue.T[Token]) -> Program {
  let token_stream : TokenStream = tokens
  let func = token_stream.parse_function()
  token_stream.expect(EOF)
  { func, }
}

///|
fn parse_function(self : TokenStream) -> Function {
  self.expect(KWInt)
  self.expect(Identifier("main"))
  self.expect(LParen)
  self.expect(KWVoid)
  self.expect(RParen)
  self.expect(LBrace)
  let stmt = self.parse_statement()
  self.expect(RBrace)
  return { name: "main", body: stmt }
}

///|
fn parse_statement(self : TokenStream) -> Stmt {
  match self.peek() {
    KWReturn => {
      let _ = self.take()
      let return_val = self.parse_exp(0)
      self.expect(Semicolon)
      return Return(return_val)
    }
    _ => @utils.die("Error Token")
  }
}

///|
pub fn parse_exp(self : TokenStream, min_prec : Int) -> Expr {
  let mut left = self.parse_factor()
  let mut next_token = self.peek()
  while is_binop(next_token) && next_token.precdence() >= min_prec {
    let op = self.parse_binop()
    let right = self.parse_exp(next_token.precdence() + 1)
    left = Binary(op, left, right)
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
      let inner_expr = self.parse_exp(0)
      self.expect(RParen)
      inner_expr
    }
    _ => @utils.die("Malformed expression")
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
fn is_binop(token : Token) -> Bool {
  token
  is (Plus
  | Hyphen
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

///| convert String to expr, only used in test
pub fn expr(expr_str : String) -> Expr {
  let tokens : TokenStream = @lexer.lex(expr_str)
  parse_exp(tokens, 0)
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
