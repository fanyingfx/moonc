// 3. Instruction fixup
///|
let fixup_instruction : (@asm.Instruction) -> Array[@asm.Instruction] = fn {
  Mov(dst=Stack(_) as dst, src=Stack(_) as src) =>
    [Mov(dst=Reg(R10), src~), Mov(dst~, src=Reg(R10))]
  Binary(Add | Sub as op, dst=Stack(_) as dst, src=Stack(_) as src) =>
    [Mov(dst=Reg(R10), src~), Binary(op, dst~, src=Reg(R10))]
  Binary(Mul, dst=Stack(_) as dst, src~) =>
    [
      Mov(dst=Reg(R11), src=dst),
      Binary(Mul, dst=Reg(R11), src~),
      Mov(dst~, src=Reg(R11)),
    ]
  Idiv(Imm(_) as imm) => [Mov(dst=Reg(R10), src=imm), Idiv(Reg(R10))]
  Cmp(Stack(_) as arg1, Stack(_) as arg2) =>
    [Mov(dst=Reg(R10), src=arg1), Cmp(Reg(R10), arg2)]
  Cmp(Imm(_) as imm,arg) =>[
    Mov(dst=Reg(R11),src=imm),
    Cmp(Reg(R11),arg)
  ]
  other => [other]
}

///|
fn fixup_function(func : @asm.Function, last_stack_slot : Int) -> @asm.Function {
  let instructions : Array[@asm.Instruction] = []
  instructions.push(AllocateStack(-last_stack_slot))
  for instr in func.instructions {
    instructions.append(fixup_instruction(instr))
  }
  { name: func.name, instructions }
}

///|
pub fn fixup_program(
  prog : @asm.Program,
  last_stack_slot : Int
) -> @asm.Program {
  { func: fixup_function(prog.func, last_stack_slot) }
}
