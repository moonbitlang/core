test "exp" {
  inspect!((0.5 : Float).exp(), content="1.6487212181091309")
  inspect!((1.0 : Float).exp(), content="2.7182817459106445")
  inspect!((0.0 : Float).exp(), content="1")
  inspect!((2.0 : Float).exp(), content="7.389056205749512")
  inspect!((-1.0 : Float).exp(), content="0.3678794503211975")
  inspect!(@float.infinity.exp(), content="Infinity")
  inspect!(@float.neg_infinity.exp(), content="0")
  inspect!((89 : Float).exp(), content="Infinity")
  inspect!((-104 : Float).exp(), content="0")
}
