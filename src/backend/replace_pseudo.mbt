// 2. replace pseudos
///|
typealias @asm.Operand

///|
priv struct State {
  mut current_offset : Int
  offset_map : Map[String, Int]
}

///|
fn replace_operand(self : State, operand : Operand) -> Operand {
  match operand {
    Pseudo(s) =>
      match self.offset_map[s] {
        Some(offset) => Stack(offset)
        None => {
          let new_offset = self.current_offset - 4
          self.current_offset = new_offset
          self.offset_map.set(s, new_offset)
          Stack(new_offset)
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
    Binary(op, dst~, src~) => {
      let new_dst = self.replace_operand(dst)
      let new_src = self.replace_operand(src)
      Binary(op, dst=new_dst, src=new_src)
    }
    Idiv(operand) => {
      let new_operand = self.replace_operand(operand)
      Idiv(new_operand)
    }
    Cmp(arg1, arg2) => {
      let arg1 = self.replace_operand(arg1)
      let arg2 = self.replace_operand(arg2)
      Cmp(arg1, arg2)
    }
    SetCC(cond_code, arg) => {
      let arg = self.replace_operand(arg)
      SetCC(cond_code, arg)
    }
    Ret | Cdq | Jmp(_) | JmpCC(_) | Label(_) as instr => instr
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
