///|
/// An abstract trait that is only implemented as String and View.
trait StringLike: Show {
  unsafe_charcode_at(Self, Int) -> Int
  length(Self) -> Int
  to_fullview(Self) -> View
  to_subview(Self, start_offset~ : Int, end_offset~ : Int) -> View
}

///|
pub impl StringLike for String with unsafe_charcode_at(self, i) {
  self.unsafe_charcode_at(i)
}

///|
pub impl StringLike for String with length(self) {
  self.length()
}

///|
pub impl StringLike for String with to_fullview(self) {
  self.view()
}

///|
pub impl StringLike for String with to_subview(self, start_offset~, end_offset~) {
  self.view(start_offset~, end_offset~)
}

///|
pub impl StringLike for View with unsafe_charcode_at(self, i) {
  self.str.unsafe_charcode_at(i + self.start)
}

///|
pub impl StringLike for View with length(self) {
  self.len()
}

///|
pub impl StringLike for View with to_fullview(self) {
  self
}

///|
pub impl StringLike for View with to_subview(self, start_offset~, end_offset~) {
  let start = self.start + start_offset
  let end = end_offset
  View::{ str: self.str, start, end }
}

///|
trait CharPredicate {
  match_char(Self, Char) -> Bool
}

///|
pub impl CharPredicate for Char with match_char(self, c) {
  self == c
}

///|
pub impl CharPredicate for Array[Char] with match_char(self, c) {
  self.contains(c)
}

///|
pub(all) type CharFn (Char) -> Bool

///|
pub impl CharPredicate for CharFn with match_char(self, c) {
  (self._)(c)
}
