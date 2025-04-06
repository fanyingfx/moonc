///|
pub(all) enum Token {
  Identifier(String)
  Constant(Int)
  //  keywords 
  KWInt
  KWVoid
  KWReturn
  KWIf
  KWElse
  KWDo
  KWWhile
  KWFor
  KWBreak
  KWContinue
  KWStatic
  KWExtern
  // punctuation 
  LParen
  RParen
  LBrace
  RBrace
  Hyphen
  DoubleHyphen
  Tilde
  Semicolon
  Plus
  Star
  Slash
  Percent
  Equal
  Bang // ! 
  LogicAnd // && 
  LogicOr //|| 
  DoubleEqual // == 
  BangEqual // != 
  LessThan
  GreaterThan
  LessOrEqual
  GreaterOrEqual
  QuestionMark
  Colon
  Comma
  EOF
  Invalid
} derive(Show, Eq)

///|
pub fn precdence(self : Token) -> Int {
  match self {
    Plus | Hyphen => 45
    Star | Slash | Percent => 50
    tok => @utils.die("\{tok} is not a Binary")
  }
}
