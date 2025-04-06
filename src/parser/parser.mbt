///|
typealias @lexer.Token

///|
pub type TokenStream @queue.T[Token] derive(Show)

///|
pub fn peek_token(self : TokenStream) -> Token {
  match self._.peek() {
    Some(tok) => tok
    _ => @utils.die("End of stream")
  }
}

///|
pub fn take_token(self : TokenStream) -> Token {
  match self._.pop() {
    Some(tok) => tok
    _ => @utils.die("End of stream")
  }
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
  match self.peek_token() {
    KWReturn => {
      let _ = self.take_token()
      let return_val = self.parse_exp()
      self.expect(Semicolon)
      return Return(return_val)
    }
    _ => @utils.die("Error Token")
  }
}

///|
fn parse_unaryop(self : TokenStream) -> UnaryOp {
  match self.take_token() {
    Hyphen => Negate
    Tilde => Complement
    _ => panic()
  }
}

///|
fn parse_exp(self : TokenStream) -> Expr {
  match self.peek_token() {
    Constant(i) => {
      let _ = self.take_token()
      Expr::Constant(i)
    }
    Tilde | Hyphen => {
      let op = self.parse_unaryop()
      let inner_expr = self.parse_exp()
      Unary(op, inner_expr)
    }
    LParen => {
      let _ = self.take_token()
      let inner_expr = self.parse_exp()
      self.expect(RParen)
      inner_expr
    }
    _ => @utils.die("Malformed expression")
  }
}

///|
fn expect(self : TokenStream, expected : Token) -> Unit {
  let actual = self.take_token()
  if actual != expected {
    println("expected:\{expected}, acutal:\{actual}")
    @utils.die("Syntax error")
  }
}

///|
pub fn parse(tokens : @queue.T[Token]) -> Program {
  let token_stream : TokenStream = tokens
  let func = token_stream.parse_function()
  token_stream.expect(EOF)
  { func: func }
}
