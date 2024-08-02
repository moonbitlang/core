type! IntError Int

test "show error" {
  fn f(b : Bool) -> String! {
    if b {
      "ok"
    } else {
      raise IntError(42)
    }
  }

  inspect!(
    f?(true),
    content=
      #|Ok("ok")
    ,
  )
  inspect!(
    f?(false),
    content="Err(moonbitlang/core/error_blackbox_test.IntError)",
  )
}
