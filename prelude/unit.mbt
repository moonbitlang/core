pub fn to_string(self : Unit) -> String {
  let _ = self
  "()"
}

pub fn op_equal(self : Unit, _other : Unit) -> Bool {
  let _ = self
  true
}

pub fn compare(self : Unit, _other : Unit) -> Int {
  let _ = self
  0
}

pub fn hash(self : Unit) -> Int {
  let _ = self
  0
}

pub fn Unit::default() -> Unit {
  ()
}
