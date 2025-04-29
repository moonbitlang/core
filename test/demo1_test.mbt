test "split_string" {
  // 基础分割（分隔符为逗号）
  assert_eq(split_string("a,b,c", ","), ["a", "b", "c"])

  // 空分隔符（将字符串分割为字符数组）
  assert_eq(split_string("abc", ""), ["a", "b", "c"])

  // 分隔符在开头
  assert_eq(split_string(",abc", ","), ["", "abc"])

  // 分隔符在结尾
  assert_eq(split_string("abc,", ","), ["abc", ""])

  // 连续分隔符
  assert_eq(split_string("a,,b", ","), ["a", "", "b"])

  // 特殊字符分隔符（如 "$"）
  assert_eq(split_string("$abc", "$"), ["", "abc"])
  assert_eq(split_string("abc$", "$"), ["abc", ""])

  // 空输入字符串
  assert_eq(split_string("", ","), [""])

  // 分隔符比字符串长
  assert_eq(split_string("abc", "abcd"), ["abc"])
}