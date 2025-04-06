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
fn parse_exp(self : TokenStream, min_prec : Int) -> Expr {
  let mut left = self.parse_factor()
  let mut next_token = self.peek()
  while next_token is (Plus | Hyphen | Star | Slash | Percent) &&
        next_token.precdence() >= min_prec {
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
