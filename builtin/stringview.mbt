struct StringView {
  buf : Ref[String]
  start : Int
  len : Int
}

pub fn length(self : StringView) -> Int {
  self.len
}

pub fn op_get(self : StringView, index : Int) -> Char {
  if index >= self.len {
    let len = self.len
    abort(
      "index out of bounds: the len is from 0 to \{len} but the index is \{index}",
    )
  }
  self.buf.val[self.start + index]
}

pub fn op_as_view(self : String, ~start : Int, ~end? : Int) -> StringView {
  let len = self.length()
  let end = match end {
    None => len
    Some(end) => end
  }
  guard start >= 0 && start <= end && end <= len else {
    abort("View start index out of bounds")
  }
  StringView::{ buf: { val: self }, start, len: end - start }
}

pub fn op_as_view(self : StringView, ~start : Int, ~end? : Int) -> StringView {
  let len = self.len
  let end = match end {
    None => len
    Some(end) => end
  }
  guard start >= 0 && start <= end && end <= len else {
    abort("View start index out of bounds")
  }
  StringView::{ buf: self.buf, start: self.start + start, len: end - start }
}

pub fn iter(self : StringView) -> Iter[Char] {
  Iter::new(
    fn(yield) {
      for i = 0; i < self.len; i = i + 1 {
        let v = self[i]
        guard let IterContinue = yield(v) else { x => break x }

      } else {
        IterContinue
      }
    },
  )
}
