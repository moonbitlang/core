///|
/// A comparison that uses the extreme results the `Compare` contract allows:
/// any negative or positive `Int`, including `Int::MIN_VALUE`.
#derive(Eq)
priv struct Extreme(Int32)

///|
impl Compare for Extreme with fn compare(a, b) {
  if a.0 < b.0 {
    -2147483648 // Int::MIN_VALUE
  } else if a.0 > b.0 {
    2147483647 // Int::MAX_VALUE
  } else {
    0
  }
}

///|
test "Reverse handles an inner compare returning Int::MIN_VALUE" {
  let one = @cmp.Reverse(Extreme(1))
  let two = @cmp.Reverse(Extreme(2))
  inspect(one < two, content="false")
  inspect(one > two, content="true")
  inspect(two < one, content="true")
  inspect(one.compare(two) > 0, content="true")
  inspect(two.compare(one) < 0, content="true")
  inspect(one.compare(one), content="0")
}

///|
test "sorting Reverse with an extreme inner compare sorts descending" {
  let arr = [@cmp.Reverse(Extreme(1)), Reverse(Extreme(3)), Reverse(Extreme(2))]
  arr.sort()
  @debug.debug_inspect(arr.map(r => r.0.0), content="[3, 2, 1]")
}
