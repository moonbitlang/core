test "exp" {
  inspect!((0.5 : Float).exp(), content="1.740578055381775")
  inspect!((1.0 : Float).exp(), content="3.020629644393921")
  inspect!((0.0 : Float).exp(), content="1")
  inspect!((2.0 : Float).exp(), content="9.026880264282227")
  inspect!((-1.0 : Float).exp(), content="0.32666537165641785")
  inspect!(@float.infinity.exp(), content="Infinity")
  inspect!(@float.neg_infinity.exp(), content="0")
  inspect!((89 : Float).exp(), content="Infinity")
  inspect!((-104 : Float).exp(), content="0")
}
