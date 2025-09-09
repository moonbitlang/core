///|
struct MatchResult(@iregex.MatchResult)

///|
pub fn MatchResult::before(self : Self) -> @string.View {
  self.0.before()
}

///|
pub fn MatchResult::after(self : Self) -> @string.View {
  self.0.after()
}

///|
pub fn MatchResult::get(self : Self, index : Int) -> @string.View? {
  self.get(index)
}

///|
struct Regex(@iregex.Regex)

///|
pub fn Regex::compile(pattern : String) -> Regex raise {
  @iregex.compile(pattern)
}

///|
pub fn Regex::execute(self : Self, input : String) -> MatchResult? {
  match self.0.match_(input) {
    None => None
    Some(result) => Some(MatchResult(result))
  }
}
