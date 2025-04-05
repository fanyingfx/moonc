///|
struct Program {
  prog : Function
}

///|
struct Function {
  identifier : String
  instructions : Array[Instruction]
}

///|
enum Instruction {
  Mov(dst~ : Operand, src~ : Operand)
  Ret
}

///|
enum Operand {
  Imm(Int)
  Register
}
