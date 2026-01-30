///|
test "diff: arrays collapse when all children differ" {
  let x = Repr::array([Repr::integer("1"), Repr::integer("2")])
  let y = Repr::array([Repr::integer("3"), Repr::integer("4")])
  match diff_repr(x, y) {
    Different(Array(_), Array(_)) => ()
    _ => fail("expected Different(Array, Array)")
  }
}

///|
test "diff: arrays keep per-element when some children same" {
  let x = Repr::array([Repr::integer("1"), Repr::integer("2")])
  let y = Repr::array([Repr::integer("1"), Repr::integer("3")])
  match diff_repr(x, y) {
    Same(Array([]), [Same(Integer("1"), []), _]) => ()
    _ => fail("expected Same(Array, children...)")
  }
}

///|
test "diff: extra elements are marked" {
  let x = Repr::array([Repr::integer("1")])
  let y = Repr::array([Repr::integer("1"), Repr::integer("2")])
  match diff_repr(x, y) {
    Same(Array([]), [Same(Integer("1"), []), Extra2(Integer("2"))]) => ()
    _ => fail("expected Same(Array, [Same 1, Extra2 2])")
  }
}

///|
test "diff: tolerant doubles compare same" {
  let x = Repr::double(1.0)
  let y = Repr::double(1.0 + 1.0e-13)
  match diff_repr(x, y, max_relative_error=1.0e-12) {
    Same(DoubleLit(_), []) => ()
    _ => fail("expected Same(DoubleLit, [])")
  }
}

///|
test "Repr is readonly but constructible via smart ctors" {
  let info = Repr::ctor("X", [(None, Repr::integer("1"))])
  match info {
    Enum("X", [Integer("1")]) => ()
    _ => fail("expected Enum(\"X\", [Integer(\"1\")])")
  }
  assert_eq(info.children().length(), 1)
  match info.shallow() {
    Enum("X", []) => ()
    _ => fail("expected shallow Enum(\"X\", [])")
  }
  match Repr::omitted() {
    Omitted => ()
    _ => fail("expected Omitted")
  }
}

///|
test "diff: extra elements on left are marked Extra1" {
  let x = Repr::array([Repr::integer("1"), Repr::integer("2")])
  let y = Repr::array([Repr::integer("1")])
  match diff_repr(x, y) {
    Same(Array([]), [Same(Integer("1"), []), Extra1(Integer("2"))]) => ()
    _ => fail("expected Same(Array, [Same 1, Extra1 2])")
  }
}

///|
test "diff: BoolLit and Literal compare by value" {
  let b1 = Repr::bool(true)
  let b2 = Repr::bool(false)
  match diff_repr(b1, b2) {
    Different(BoolLit(true), BoolLit(false)) => ()
    _ => fail("expected Different(BoolLit, BoolLit)")
  }
  let l1 = Repr::literal("X")
  let l2 = Repr::literal("Y")
  match diff_repr(l1, l2) {
    Different(Literal("X"), Literal("Y")) => ()
    _ => fail("expected Different(Literal, Literal)")
  }
}

///|
test "diff: mismatched label kinds are Different" {
  let x = Repr::integer("1")
  let y = Repr::string("1")
  match diff_repr(x, y) {
    Different(Integer("1"), StringLit("1")) => ()
    _ => fail("expected Different(Integer, StringLit)")
  }
}
