
pub fn assert_eq[T : Debug + Eq](a : T, b : T) {
  if a != b {
    let buf = Buffer::make(100)
    "assertion failed: ".debug_write(buf)
    a.debug_write(buf)
    " == ".debug_write(buf)
    b.debug_write(buf)
    "\n".debug_write(buf)
    abort(buf.to_string())
  }
}

pub fn assert_false(b : Bool) {
  if b {
    let buf = Buffer::make(100)
    "assertion failed: ".debug_write(buf)
    b.debug_write(buf)
    " == false".debug_write(buf)
    "\n".debug_write(buf)
    abort(buf.to_string())
  }
}

pub fn assert_true(b : Bool) {
  if not (b) {
    let buf = Buffer::make(100)
    buf.write_string("assertion failed: ")
    b.debug_write(buf)
    buf.write_string(" == true\n")
    abort(buf.to_string())
  }
}

test "assert_true.true" {
  assert_true(true)
}

test "assert_false.false" {
  assert_false(false)
}

test "assert_eq.eq" {
  assert_eq(1, 1)
}
