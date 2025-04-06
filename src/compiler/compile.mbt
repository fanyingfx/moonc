///|
pub fn gen_asm(prog : @tacky.Program) -> @asm.Program {
  let asm_ast = @backend.convert_program(prog)
  let (asm_ast, stack_size) = @backend.replace_pseudos(asm_ast)
  // println(asm_ast)
  let asm_ast = @backend.fixup_program(asm_ast, stack_size)
  asm_ast
}
