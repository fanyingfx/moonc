typealias @token.(Token)
///|
struct Lexer {
  len : Int
  content : String
  mut pos : Int
  mut ch : Char?
}

///|
let keywords : Map[String, Token] = {
  "int": KWInt,
  "void": KWVoid,
  "return": KWReturn,
  "if": KWIf,
  "else": KWElse,
  "do": KWDo,
  "while": KWWhile,
  "for": KWFor,
  "break": KWBreak,
  "continue": KWContinue,
  "static": KWStatic,
  "extern": KWExtern,
}

///|
fn Lexer::new(content : String) -> Lexer {
  let lexer = { content, pos: -1, len: content.length(), ch: None }
  lexer.advance_char()
  return lexer
}

///|
fn peek_char(self : Lexer) -> Char? {
  if self.pos + 1 >= self.len {
    return None
  }
  return Some(self.content[self.pos + 1])
}

///|
fn advance_char(self : Lexer) -> Unit {
  self.ch = self.peek_char()
  self.pos += 1
}

///|
fn eat_while(self : Lexer, predicate : (Char?) -> Bool) -> String {
  let start_pos = self.pos
  while predicate(self.peek_char()) {
    self.advance_char()
  }
  return self.content.substring(start=start_pos, end=self.pos+1)
}

///|
fn skip_whitespace(self : Lexer) -> Unit {
  // println("current char:\{self.ch}")
  while self.ch is Some(' ' | '\n' | '\r' | '\t') {
    // println("Space")
    self.advance_char()
  }
  // self.advance_char()
}

///|
fn make_int(self : Lexer) -> Token {
  fn is_digit(c : Char?) -> Bool {
    match c {
      Some('0'..='9') => true
      Some('a'..='z' | 'A'..='Z') => panic()
      _ => false
    }
  }

  let value_str = self.eat_while(is_digit)
  let v = try {
    @strconv.parse_int!(value_str)
  } catch {
    StrConvError(_) => {
      println("Parser Int Error, pos\{self.pos}")
      abort("Error ")
    }
  }
  Constant(v)
}

///|
fn make_ident_or_keyword(self : Lexer) -> Token {
  fn is_alphabelt(opt : Char?) -> Bool {
    match opt {
      Some('a'..='z' | 'A'..='Z' | '_' | '0'..='9') => true
      _ => false
    }
  }

  let idstr = self.eat_while(is_alphabelt)
  match keywords[idstr] {
    None => Identifier(idstr)
    Some(kw) => kw
  }
}

///|
fn next_token(self : Lexer) -> Token {
  self.skip_whitespace()
  let tok : Token = match self.ch {
    Some(ch) =>
      match ch {
        '0'..='9' => self.make_int()
        'a'..='z' | 'A'..='Z' | '_' => self.make_ident_or_keyword()
        '(' => LParen
        ')' => RParen
        '{' => LBrace
        '}' => RBrace
        ';' => Semicolon
        '~' => Tilde
        '+' => Plus
        '*' => Star
        '/' => Slash
        '%' => Percent
        '?' => QuestionMark
        ':' => Colon
        ',' => Comma
        _ => @utils.die("Cannot get next_token")
      }
    None => EOF
  }
  self.advance_char()
  return tok
}

///|
pub fn lex(content : String) -> @queue.T[Token] {
  let lexer = Lexer::new(content)
  let tokens  = @queue.new()
  while true {
    match lexer.next_token() {
      EOF => break
      tok => tokens.push(tok)
    }
  }
  tokens.push(EOF)
  return tokens
}
