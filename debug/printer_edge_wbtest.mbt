///|
test "pretty_printer: empty_content prints empty" {
  inspect(print_content(empty_content().no_wrap()), content="")
}

///|
test "pretty_printer: surround_lines handles empty and singleton" {
  let empty = surround("(", ")", verbatim(""))
  inspect(print_content(empty), content="()")
  let single = surround("(", ")", verbatim("x"))
  inspect(print_content(single), content="(x)")
}

///|
test "pretty_printer: compact_lines handles empty and multiline" {
  let content = comma_seq("", "", [verbatim("a"), verbatim("b"), verbatim("c")])
  let compact = content.compact()
  inspect(print_content(compact.no_wrap()), content="a, b, c")
}

///|
test "pretty_printer: comma_seq_lines filters empty lines" {
  let empty = comma_seq("", "", [])
  inspect(print_content(empty.no_wrap()), content="")
}
