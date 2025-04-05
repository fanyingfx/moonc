///|
fn main {
  let return_2 =
    #| int main(void){
    #|   return 2;
    #|}
  
  let tokens = @lex.lex(return_2)

  let ast = @parser.parse(tokens)
  println(ast)
}
