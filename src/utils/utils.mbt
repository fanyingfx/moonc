///|
pub fn die[T](msg : String, loc~ : SourceLoc = _) -> T {
  println("\{loc} \{msg}")
  panic()
}

///|
let counter : Ref[Int] = { val: 0 }

///|

///|
pub fn make_temporary() -> String {
  let n = counter.val
  counter.val += 1
  "tmp.\{n}"
}

///|
/// only can use in test
pub fn reset_counter() -> Unit {
  counter.val = 0
  counter.val = 0
}

///|
pub fn make_label(label : String) -> String {
  let n = counter.val
  counter.val += 1
  "\{label}_\{n}"
}
