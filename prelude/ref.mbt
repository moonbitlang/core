pub fn to_string[X : Show](self : Ref[X]) -> String {
  "{val: " + self.val.to_string() + "}"
}
