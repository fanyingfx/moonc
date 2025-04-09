///|
pub fn gen_asm(prog : @tacky.Program) -> @asm.Program {
  let asm_ast = @backend.convert_program(prog)
  let (asm_ast, stack_size) = @backend.replace_pseudos(asm_ast)
  // println(asm_ast)
  let asm_ast = @backend.fixup_program(asm_ast, stack_size)
  asm_ast
}
test "basic gen_asm"{
  let content =
  #|int main(void){
  #|  return 2<3 && 5>4;
  #|}
  let asm = content
    |> @lexer.lex
    |> @parser.parse
    |> @semantic_analysis.validate
    |> @tacky.gen_tacky
    |> gen_asm

  inspect!(asm, content=
    #|{func: {name: "main", instructions: [AllocateStack(12), Mov(dst=Reg(R11), src=Imm(2)), Cmp(Reg(R11), Imm(3)), Mov(dst=Stack(-4), src=Imm(0)), SetCC(L, Stack(-4)), Cmp(Stack(-4), Imm(0)), JmpCC(E, "false_0"), Mov(dst=Reg(R11), src=Imm(5)), Cmp(Reg(R11), Imm(4)), Mov(dst=Stack(-8), src=Imm(0)), SetCC(G, Stack(-8)), Cmp(Stack(-8), Imm(0)), JmpCC(E, "false_0"), Mov(dst=Stack(-12), src=Imm(1)), Jmp("end_1"), Label("false_0"), Mov(dst=Stack(-12), src=Imm(0)), Label("end_1"), Mov(dst=Reg(AX), src=Stack(-12)), Ret]}}

  )
}
