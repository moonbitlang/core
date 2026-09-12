# Double formatting in `builtin`

`Double::to_string()` is implemented in `builtin`. On non-JavaScript backends,
the private `ryu_to_string` helper uses Ryu to produce a decimal representation
that parses back to the same finite value. On JavaScript, the helper delegates
to the JavaScript number's `toString()` method.

The private helper is an implementation detail. Applications use the public
`Double::to_string()` method, string interpolation, or `Show`.

```mbt check
///|
test "double decimal formatting" {
  inspect(123.456.to_string(), content="123.456")
  inspect(0.5.to_string(), content="0.5")
  inspect(8.0.to_string(), content="8")
  inspect((-42.5).to_string(), content="-42.5")
}
```

The formatter follows ECMAScript's choice between fixed and exponential
notation. It uses enough significant digits to distinguish the value, rather
than printing its full exact decimal expansion.

```mbt check
///|
test "double notation boundaries" {
  inspect(1.0e-6.to_string(), content="0.000001")
  inspect(1.0e-7.to_string(), content="1e-7")
  inspect(1.0e20.to_string(), content="100000000000000000000")
  inspect(1.0e21.to_string(), content="1e+21")
}
```

Positive and negative zero both format as `"0"`; the sign of zero is not
preserved. NaN and infinities use the following spellings:

```mbt check
///|
test "double special value formatting" {
  inspect((-0.0).to_string(), content="0")
  inspect((0.0 / 0.0).to_string(), content="NaN")
  inspect((1.0 / 0.0).to_string(), content="Infinity")
  inspect((-1.0 / 0.0).to_string(), content="-Infinity")
}
```

The non-JavaScript implementation uses precomputed powers, integer arithmetic,
and a fast path for integral values. Its algorithm is based on Ulf Adams's
paper *Ryu: fast float-to-string conversion*.
