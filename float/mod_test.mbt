fn check(x : Float, y : Float) -> Bool {
  (x - y).abs() < 1.0e-4
}

test "mod" {
  inspect!(check((7.5 : Float) % 2.3, 0.6), content="true")
  inspect!(check((5.75 : Float) % 5.75, 0), content="true")
  inspect!(check((-3.6 : Float) % 1.4, -0.8), content="true")
  inspect!(check((15.25 : Float) % 4.5, 1.75), content="true")
  inspect!(check((0.7 : Float) % 0.2, 0.1), content="true")
  inspect!(check((-8.4 : Float) % 3.2, -2), content="true")
}
