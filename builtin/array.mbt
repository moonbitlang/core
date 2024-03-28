pub fn to_string[X : Show](self : Array[X]) -> String {
  let mut acc = "["
  for i = 0; i < self.length(); i = i + 1 {
    if i > 0 {
      acc = acc + ", "
    }
    acc = acc + self[i].to_string()
  }
  acc + "]"
}

pub fn Array::default[X]() -> Array[X] {
  []
}
