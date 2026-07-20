///|
test "V128 decode handles a view and scalar tail" {
  let bytes = b"!0123456789ABCDEF?"
  inspect(decode_v128(bytes[1:]), content="0123456789ABCDEF?")
}

///|
test "V128 decode reports the first non-ASCII byte in a block" {
  let bytes = b"0123456789ABC\xffDEF"
  try {
    let _ = decode_v128(bytes)
    panic()
  } catch {
    Malformed(rest) =>
      inspect(
        rest,
        content=(
          #|b"\xffDEF"
        ),
      )
  }
}
