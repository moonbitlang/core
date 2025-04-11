# MoonBit QuickCheck Package

MoonBit QuickCheck package provides property-based testing capabilities by generating random test inputs.

## Basic Usage

Generate random values of any type that implements the `Arbitrary` trait:

```moonbit
test "basic generation" {
  let b : Bool = @quickcheck.gen()
  inspect!(b, content="true")
  let x : Int = @quickcheck.gen()
  inspect!(x, content="0")

  // Generate with size parameter
  let sized : Array[Int] = @quickcheck.gen(size=5)
  inspect!(sized.length() <= 5, content="true")
}
```

## Multiple Samples

Generate multiple test cases using the `samples` function:

```moonbit
test "multiple samples" {
  let ints : Array[Int] = @quickcheck.samples(5)
  inspect!(ints, content="[0, 0, 0, -1, -1]")
  let strings : Array[String] = @quickcheck.samples(12)
  inspect!(
    strings[5:10],
    content=
      #|["\b", " (rK\x1f", "v!@Zx", "Lx", "2&\bx@\x07qh"]
    ,
  )
}
```

## Built-in Types

QuickCheck provides `Arbitrary` implementations for all basic MoonBit types:

```moonbit
test "builtin types" {
  // Basic types
  let _b : Bool = @quickcheck.gen()
  let _c : Char = @quickcheck.gen()
  let _byte : Byte = @quickcheck.gen()

  // Numeric types
  let _i : Int = @quickcheck.gen()
  let _i64 : Int64 = @quickcheck.gen()
  let _ui : UInt = @quickcheck.gen()
  let _ui64 : UInt64 = @quickcheck.gen()
  let _f : Float = @quickcheck.gen()
  let _d : Double = @quickcheck.gen()
  let _bi : BigInt = @quickcheck.gen()

  // Collections
  let _s : String = @quickcheck.gen()
  let _bs : Bytes = @quickcheck.gen()
  let _it : Iter[Int] = @quickcheck.gen()

}
```

## Custom Types

Implement `Arbitrary` trait for custom types:

```moonbit
struct Point {
  x : Int
  y : Int
} derive(Show)

impl Arbitrary for Point with arbitrary(size, r0) {
  let r1 = r0.split()
  let y = Arbitrary::arbitrary(size, r1)
  { x: Arbitrary::arbitrary(size, r0), y }
}

test "custom type generation" {
  let point : Point = @quickcheck.gen()
  inspect!(point, content="{x: 0, y: 0}")
  let points : Array[Point] = @quickcheck.samples(10)
  inspect!(
    points[6:],
    content="[{x: 0, y: 1}, {x: -1, y: -5}, {x: -6, y: -6}, {x: -1, y: 7}]",
  )
}
```

The package is useful for writing property tests that verify code behavior across a wide range of randomly generated inputs.
