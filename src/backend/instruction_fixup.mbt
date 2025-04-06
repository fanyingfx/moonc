// 3. Instruction fixup
///|
fn fixup_instruction(instruction : @asm.Instruction) -> Array[@asm.Instruction] {
  match instruction {
    Mov(dst=Stack(_) as dst, src=Stack(_) as src) =>
      [Mov(dst=Reg(R10),src~), Mov(dst~, src=Reg(R10))]
    other => [other]
  }
}

///|
fn fixup_function(
  func : @asm.Function,
  last_stack_slot : Int
) -> @asm.Function {
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
