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
    assert_eq!(tuple.0, 1)
    assert_eq!(tuple.1, 2)
    assert_eq!(@tuple.fst(tuple), 1)
    assert_eq!(@tuple.snd(tuple), 2)
}
```

## Transformation

You can transform the tuple using the `map_fst` and `map_snd` method, which will apply the function to the first and second element of the tuple respectively.

```moonbit  
test {
    let tuple = (1, 2)
    let _tuple2 = @tuple.map_fst(fn(x) { x + 1 }, tuple) // tuple2 = (2, 2)
    let _tuple3 = @tuple.map_snd(fn(x) { x + 1 }, tuple) // tuple3 = (1, 3)
}
```

Or you can use the `map_both` method to apply the function to both elements of the tuple.

```moonbit
test {
    let tuple = (1, 2)
    let _mapped = @tuple.map_both(
        fn(x : Int) -> Int { x + 1 },
        fn(x : Int) -> Int { x - 1 },
        tuple
    ) // mapped = (2, 1)
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

