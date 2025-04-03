///|
pub fn trim_start_by[S : StringLike, P : CharPredicate](s : S, p : P) -> View {
  loop s.to_fullview() {
    [] as v => v
    [c, .. rest] as v => if p.match_char(c) { continue rest } else { v }
  }
}

///|
pub fn trim_prefix[S1 : StringLike, S2 : StringLike](
  s : S1,
  prefix : S2
) -> View {
  let prefix_len = prefix.length()
  let len = s.length()
  guard len >= prefix_len else { return s.to_fullview() }
  for i in 0..<prefix_len {
    guard s.unsafe_charcode_at(i) == prefix.unsafe_charcode_at(i) else {
      return s.to_fullview()
    }

  }
  s.to_subview(start_offset=prefix_len, end_offset=len)
}

///|
pub fn trim_end_by[S : StringLike, P : CharPredicate](s : S, p : P) -> View {
  loop s.to_fullview() {
    [] as v => v
    [.. rest, c] as v => if p.match_char(c) { continue rest } else { v }
  }
}

///|
pub fn trim_suffix[S1 : StringLike, S2 : StringLike](
  s : S1,
  suffix : S2
) -> View {
  let suffix_len = suffix.length()
  let len = s.length()
  guard len >= suffix_len else { return s.to_fullview() }
  for i in 0..<suffix_len {
    guard s.unsafe_charcode_at(len - i - 1) ==
      suffix.unsafe_charcode_at(suffix_len - i - 1) else {
      return s.to_fullview()
    }

  }
  s.to_subview(start_offset=0, end_offset=len - suffix_len)
}
