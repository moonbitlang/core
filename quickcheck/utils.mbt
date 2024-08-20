pub fn samples[X : Arbitrary](x : Int) -> Array[X] {
  let rs = @splitmix.RandomState::new()
  let array = Array::make(x, X::arbitrary(0, rs))
  for i = 1; i < x; i = i + 1 {
    array[i] = X::arbitrary(i, rs)
  }
  array
}
