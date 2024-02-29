
fn debug_string[T : Debug](t : T) -> String {
  let buf = Buffer::make(50)
  t.debug_write(buf)
  buf.to_string()
}

pub fn assert_eq[T : Debug + Eq](a : T, b : T) -> Result[Unit,String] {
  if a == b {
    Ok(())
  } else {
    let a = debug_string(a)
    let b = debug_string(b)
    Err("assertion failed for `\(a) == \(b)`")
  }
}

pub fn assert_ne[T : Debug + Eq](a : T, b : T) -> Result[Unit,String] {
  if a != b {
    Ok(())
  } else {
    let a = debug_string(a)
    let b = debug_string(b)
    Err("assertion failed for `\(a) == \(b)`")
  }
}

pub fn assert_false(x : Bool) -> Result[Unit,String] {
  if x == false {
    Ok(())
  } else {
    Err("assert_false failed")
  }
}

pub fn assert_true(x : Bool) -> Result[Unit,String] {
  if x {
    Ok(())
  } else {
    Err("assert_true failed")
  }
}

test "assert_true.true" {
  assert_true(true)?
}

test "assert_false.false" {
  assert_false(false)?
}

test "assert_eq.eq" {
  assert_eq(1, 1)?
  assert_eq("123","123")?
}
