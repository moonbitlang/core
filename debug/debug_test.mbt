///|
test "inspect" {
  @debug.inspect(
    Some("msg"),
    content=(
      #|Some("msg")
    ),
  )
  @debug.inspect(
    @list.from_array(["data1", "data2"]),
    content=(
      #|<List: ["data1", "data2"]>
    ),
  )
}
