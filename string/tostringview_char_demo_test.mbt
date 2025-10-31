///|
test "ToStringView for Char - comprehensive demo" {
  // Test 1: Simple join without separator
  let chars1 : Array[Char] = ['h', 'e', 'l', 'l', 'o']
  let result1 = chars1.join("")
  inspect(result1, content="hello")

  // Test 2: Join with separator
  let chars2 : Array[Char] = ['a', 'b', 'c', 'd']
  let result2 = chars2.join(", ")
  inspect(result2, content="a, b, c, d")

  // Test 3: Empty array
  let chars3 : Array[Char] = []
  let result3 = chars3.join("-")
  inspect(result3, content="")

  // Test 4: Single character
  let chars4 : Array[Char] = ['x']
  let result4 = chars4.join(" | ")
  inspect(result4, content="x")

  // Test 5: Unicode characters
  let chars5 : Array[Char] = ['🌟', '✨', '🎉']
  let result5 = chars5.join(" ")
  inspect(result5, content="🌟 ✨ 🎉")
}
