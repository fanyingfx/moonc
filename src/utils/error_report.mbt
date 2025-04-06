///|

///|
let counter :Ref[Int]={val:0}

///|
pub fn die[T](msg : String) -> T {
  println("\{msg}")
  panic()
}

///|
pub fn make_temporary() -> String {
  let n = counter.val
  counter.val += 1
  "tmp." + n.to_string()
}
