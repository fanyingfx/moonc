// 2. replace pseudos
///|
typealias @asm.Operand

///|
struct State {
  mut current_offset : Int
  offset_map : Map[String, Int]
}

///|
fn replace_operand(self : State, operand : Operand) -> Operand {
  match operand {
    Pseudo(s) =>
      match self.offset_map[s] {
        Some(offset) => Stack(offset, DWord)
        None => {
          let new_offset = self.current_offset - 4
          self.current_offset = new_offset
          self.offset_map.set(s, new_offset)
          Stack(new_offset, DWord)
        }
      }
    operand => operand
  }
}

///|
fn replace_pseudos_in_instruction(
  self : State,
  instruction : @asm.Instruction
) -> @asm.Instruction {
  match instruction {
    Mov(dst~, src~) => {
      let new_src = self.replace_operand(src)
      let new_dst = self.replace_operand(dst)
      Mov(dst=new_dst, src=new_src)
    }
    Unary(op, dst) => {
      let new_dst = self.replace_operand(dst)
      Unary(op, new_dst)
    }
    Ret => Ret
    AllocateStack(_) =>
      @utils.die("AllocateStack shouldn't be present at this point")
  }
}

///|
fn replace_pseudos_in_function(func : @asm.Function) -> (@asm.Function, Int) {
  let state : State = { current_offset: 0, offset_map: {} }
  let new_instructions = []
  for instr in func.instructions {
    new_instructions.push(state.replace_pseudos_in_instruction(instr))
  }
  ({ name: func.name, instructions: new_instructions }, state.current_offset)
}

///|
pub fn replace_pseudos(program : @asm.Program) -> (@asm.Program, Int) {
  let (func, last_stack_slot) = replace_pseudos_in_function(program.func)
  ({ func, }, last_stack_slot)
}
