test "parse" {
  let val = parse(
    #| // single line comment
    #| /* multi line comment
    #| */
    #| {a: "bc"}
  ).map_err(fn(_err) { "error" })?
  ignore(val)
}
