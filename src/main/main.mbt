///|
type CFile String derive(Show)

///|
fn get_cfile() -> CFile {
  let args = @sys.get_cli_args()
  if args.length() != 3 {
    @utils.die("Wrong args")
  }
  let file_name = args[2]
  if not(file_name.ends_with(".c")) {
    @utils.die("\{file_name} is not a c file")
  }
  return file_name
}

///|
fn asm_file(self : CFile) -> String {
  self._.trim_end(".c") + ".asm"
}

///|
fn main {
  let cfile = get_cfile()
  let content = @fs.read_file_to_string?(cfile._).unwrap()
  let tokens = @lexer.lex(content)
  let ast = @parser.parse(tokens)
  // let asm_ast = @codegen.gen_asm(ast)
  let tacky = @tacky.gen_tacky(ast)
  let asm = @compiler.gen_asm(tacky)
  let _ = @emit.emit(cfile.asm_file(), asm)

  // let fixup = @backend.fixup_program(tacky)

}
