# Tuple

Tuple is a fixed-size collection of elements of different types. It is a lightweight data structure that can be used to store multiple values in a single variable. This sub-package introduces utils for binary tuples.

# Usage

## Create

Create a new tuple by `pair` or using the tuple literal syntax.

```moonbit
test {
    let _tuple = @tuple.pair(1, 2)
    let _tuple2 = (1, 2)
}
```

## Access

You can access the elements of the tuple using the `fst` and `snd` methods (Shortly use dot access).

```moonbit
test {
    let tuple = (1, 2)
    assert_eq(tuple.0, 1)
    assert_eq(tuple.1, 2)
    assert_eq(@tuple.fst(tuple), 1)
    assert_eq(@tuple.snd(tuple), 2)
}
```

## Transformation

You can transform the tuple using the matrix functions combined with `then`.

```moonbit  
test {
    let tuple = (1, 2)
    let _tuple2 = (fn { (x, y) => (x + 1, y) })(tuple) // tuple2 = (2, 2)
    let _tuple3 = tuple |> then(fn { (x, y) => (x, y + 1) }) // tuple3 = (1, 3)
    let _mapped = tuple |> then(fn(pair) { (pair.0 + 1, pair.1 - 1) }) // _mapped = 2, 1
}
```

## Conversion
Swap the elements of the tuple using the `swap` method.

```moonbit
test {
    let tuple = (1, 2)
    let _swapped = @tuple.swap(tuple) // swapped = (2, 1)
}
```

## Currying
Moonbit provides a currying method for the tuple. You can use the `curry` method to convert a function into a curried function.

```moonbit
test {
    let add = fn(a, b) { a + b }
    let curried_add = @tuple.curry(add)
    let _result = curried_add(1)(2) // result = 3
}
```

The dual of the `curry` method is the `uncurry` method, which converts a curried function back to a normal function.

```moonbit
test {
    let add = fn(a) { fn(b) { a + b } }
    let uncurried_add = @tuple.uncurry(add)
    let _result = uncurried_add(1, 2) // result = 3
}
```

