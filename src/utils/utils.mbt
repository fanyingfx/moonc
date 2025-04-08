///|
pub fn die[T](msg : String, loc~ : SourceLoc = _) -> T {
  println("\{loc} \{msg}")
  panic()
}

///|
let counter_temp : Ref[Int] = { val: 0 }

///|
let counter_label : Ref[Int] = { val: 0 }

///|
pub fn make_temporary() -> String {
  let n = counter_temp.val
  counter_temp.val += 1
  "tmp.\{n}"
}

///|
/// only can use in test
pub fn reset() -> Unit {
  counter_temp.val = 0
  counter_label.val = 0
}

///|
pub fn make_label(label : String) -> String {
  let n = counter_label.val
  counter_label.val += 1
  "\{label}_\{n}"
}
