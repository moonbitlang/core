# LazyList

A persistent, re-traversable linked list with memoized lazy tails. Built on
top of `@lazy.Lazy`. Use it when you have a pull-based source (`Iter`,
generator, recursive definition) that you want to consume *more than once*
without re-running the underlying computation.

## Table of Contents

1. [When to reach for `LazyList`](#when-to-reach-for-lazylist)
2. [Mental model](#mental-model)
3. [Constructing](#constructing)
4. [Observing](#observing)
5. [Transforming](#transforming)
6. [Consuming strictly](#consuming-strictly)
7. [Inspecting with `Debug`](#inspecting-with-debug)
8. [Design trade-offs](#design-trade-offs)

---

## When to reach for `LazyList`

| You want…                                                           | Use                            |
|---------------------------------------------------------------------|--------------------------------|
| A one-shot pipeline over a sequence                                 | `Iter`                         |
| A strict, fully realized linked list                                | `@list.List`                   |
| A sequence you can re-traverse, defined recursively or infinitely   | **`@lazy_list.LazyList`**      |
| A sequence whose elements are expensive to compute and worth caching across multiple traversals | **`@lazy_list.LazyList`** |

`LazyList` shines exactly when re-traversal matters. If you'll consume a
sequence once, `Iter` is simpler and cheaper.

---

## Mental model

`LazyList[A]` is **head-strict / tail-lazy**. Every cell either:

- is empty, or
- holds a fully evaluated head element and a *memoized thunk* for the rest.

The thunk runs at most once. After it runs, the result is cached in place,
so a second traversal walks the cached cells instead of re-evaluating.

This shape mirrors Haskell's lazy lists / Scala's `LazyList` and is sometimes
called "odd-style" laziness.

---

## Constructing

There are three primitive constructors: `empty`, `lazy_cons`, and
`from_iter`. Everything else is a one-liner.

### `empty`

```mbt check
///|
test {
  let xs : @lazy_list.LazyList[Int] = @lazy_list.empty()
  inspect(xs.is_empty(), content="true")
}
```

### `lazy_cons` — recursive infinite streams

The primary builder for recursive streams. Both `repeat` and `iterate` are
two-line definitions on top of `lazy_cons`:

```mbt check
///|
test {
  fn repeat(value : Int) -> @lazy_list.LazyList[Int] {
    @lazy_list.lazy_cons(value, () => repeat(value))
  }

  fn iterate(seed : Int, f : (Int) -> Int) -> @lazy_list.LazyList[Int] {
    @lazy_list.lazy_cons(seed, () => iterate(f(seed), f))
  }

  debug_inspect(repeat(7).take(3).to_array(), content="[7, 7, 7]")
  debug_inspect(
    iterate(1, x => x * 2).take(5).to_array(),
    content="[1, 2, 4, 8, 16]",
  )
}
```

### `from_iter` — re-traversable wrapper around any `Iter`

`from_iter` is the unique value-add of this package: it memoizes pulls from
an `Iter` so the resulting `LazyList` can be traversed multiple times
without re-running the source.

```mbt check
///|
test {
  let xs = @lazy_list.from_iter([1, 2, 3].iter())
  // First traversal computes and caches cells.
  debug_inspect(xs.to_array(), content="[1, 2, 3]")
  // Second traversal walks the cache — no further pulls from the iter.
  debug_inspect(xs.to_array(), content="[1, 2, 3]")
}
```

This makes `from_iter` the canonical bridge from *any* source: a strict
list, an array, an unfolding generator. We deliberately don't provide
`from_array` / `from_list` shortcuts — pipe `.iter()` into `from_iter`:

```mbt check
///|
test {
  let from_arr = @lazy_list.from_iter([1, 2, 3].iter())
  let from_list = @lazy_list.from_iter(@list.from_array([4, 5, 6]).iter())
  debug_inspect(from_arr.to_array(), content="[1, 2, 3]")
  debug_inspect(from_list.to_array(), content="[4, 5, 6]")
}
```

---

## Observing

`is_empty`, `head`, and `tail` inspect the current cell without forcing more
than necessary. `is_empty` and `head` never force anything; `tail` forces one
cell.

```mbt check
///|
test {
  let xs = @lazy_list.from_iter([1, 2, 3].iter())
  inspect(xs.is_empty(), content="false")
  debug_inspect(xs.head(), content="Some(1)")
  debug_inspect(xs.tail().unwrap().head(), content="Some(2)")
}
```

To bridge back to a pull-based iterator, use `iter`. Each call returns a
fresh traversal — the underlying `LazyList` is not consumed.

```mbt check
///|
test {
  let xs = @lazy_list.from_iter([1, 2, 3].iter())
  let i1 = xs.iter()
  let i2 = xs.iter()
  debug_inspect(i1.next(), content="Some(1)")
  // Independent state per iterator.
  debug_inspect(i2.next(), content="Some(1)")
}
```

---

## Transforming

`map`, `filter`, `take`, `drop`, `take_while`, `drop_while`, `concat`,
`flat_map`, `zip`. All of these preserve the re-traversable memoized
structure.

```mbt check
///|
test {
  let xs = @lazy_list.from_iter([1, 2, 3, 4, 5].iter())
  debug_inspect(xs.map(x => x * x).to_array(), content="[1, 4, 9, 16, 25]")
  debug_inspect(xs.filter(x => x % 2 == 0).to_array(), content="[2, 4]")
  debug_inspect(xs.take(3).to_array(), content="[1, 2, 3]")
  debug_inspect(xs.drop(3).to_array(), content="[4, 5]")
}
```

The transforms are lazy enough to work on infinite streams:

```mbt check
///|
test {
  fn iterate(seed : Int, f : (Int) -> Int) -> @lazy_list.LazyList[Int] {
    @lazy_list.lazy_cons(seed, () => iterate(f(seed), f))
  }

  let primes_so_far = iterate(2, x => x + 1)
    .filter(x => x % 2 != 0 || x == 2)
    .take_while(x => x < 20)
    .to_array()
  debug_inspect(primes_so_far, content="[2, 3, 5, 7, 9, 11, 13, 15, 17, 19]")
}
```

### `flat_map` and `zip`

```mbt check
///|
test {
  let xs = @lazy_list.from_iter([1, 2, 3].iter())
  let ys = @lazy_list.from_iter(["a", "b", "c"].iter())
  debug_inspect(
    xs.flat_map(x => @lazy_list.from_iter([x, x * 10].iter())).to_array(),
    content="[1, 10, 2, 20, 3, 30]",
  )
  debug_inspect(
    xs.zip(ys).to_array(),
    content=(
      #|[(1, "a"), (2, "b"), (3, "c")]
    ),
  )
}
```

---

## Consuming strictly

`each`, `fold`, `to_array` force the entire spine. **Do not call them on an
infinite list.** If you need a strict `@list.List`, pipe the iterator
through `@list.from_iter`:

```mbt check
///|
test {
  let xs = @lazy_list.from_iter([1, 2, 3].iter())
  let strict : @list.List[Int] = @list.from_iter(xs.iter())
  @debug.debug_inspect(strict, content="<List: [1, 2, 3]>")
}
```

```mbt check
///|
test {
  let xs = @lazy_list.from_iter([1, 2, 3, 4].iter())
  inspect(xs.fold(init=0, (acc, x) => acc + x), content="10")
  let total : Ref[Int] = Ref(0)
  xs.each(x => total.val = total.val + x)
  inspect(total.val, content="10")
  debug_inspect(xs.to_array(), content="[1, 2, 3, 4]")
}
```

For one-shot consumption you can also bridge to `Iter` — that gives you the
full `Iter` combinator set:

```mbt check
///|
test {
  let xs = @lazy_list.from_iter([1, 2, 3, 4, 5].iter())
  inspect(xs.iter().count(), content="5")
  debug_inspect(xs.iter().nth(2), content="Some(3)")
}
```

---

## Inspecting with `Debug`

`Debug` walks only the cells that have *already been forced*. Safe to call on
infinite streams — they render with `...` for the unforced tail.

```mbt check
///|
test {
  fn iterate(seed : Int, f : (Int) -> Int) -> @lazy_list.LazyList[Int] {
    @lazy_list.lazy_cons(seed, () => iterate(f(seed), f))
  }

  let stream = iterate(0, x => x + 1)
  @debug.debug_inspect(stream, content="<LazyList: [0, ...]>")
  // Force a prefix; subsequent `Debug` shows what's been memoized.
  let _ = stream.iter().take(3).each(_ => ())
  @debug.debug_inspect(stream, content="<LazyList: [0, 1, 2, ...]>")
}
```

Note: `Show`, `Eq`, and `ToJson` are deliberately **not** provided. Each
would force the entire spine and silently diverge on infinite lists. Use
`Debug` for inspection; for equality / serialization, materialize through
`to_array` (or `@list.from_iter(xs.iter())`) once you're sure the list is finite.

---

## Design trade-offs

### Why head-strict / tail-lazy (odd-style)?

Each `Cons` cell carries a forced head, so `is_empty` and `head` are O(1)
and never trigger user-supplied thunks. The alternative, even-style
(`Lazy[Empty | Cons(...)]`), wraps the *whole* list in a thunk — making
emptiness check itself a forcing operation. Odd-style is what Haskell's `[]`
and Scala's `LazyList` use, and it's simpler to reason about.

### Why is `drop_while` eager but `take_while` lazy?

```mbt check
///|
test {
  fn iterate(seed : Int, f : (Int) -> Int) -> @lazy_list.LazyList[Int] {
    @lazy_list.lazy_cons(seed, () => iterate(f(seed), f))
  }

  // take_while is lazy enough to bound an infinite stream.
  debug_inspect(
    iterate(0, x => x + 1).take_while(x => x < 5).to_array(),
    content="[0, 1, 2, 3, 4]",
  )
}
```

This asymmetry is forced by head-strict semantics:

- `take_while` builds a *new* prefix. Each output cell wraps the next step
  in a thunk, so consumers only pay for what they observe. This is critical
  for bounded consumption of infinite streams.

- `drop_while` returns the *suffix* of the source. To produce a `LazyList`
  whose head is the first non-matching element, it must walk the source
  until the predicate fails — there's no head to put in a `Cons` cell
  before that point. So the skip is necessarily eager. Once the suffix is
  identified, its tails remain lazy.

This is the same shape as Haskell:

```
takeWhile p (x:xs) | p x = x : takeWhile p xs   -- lazy cons
dropWhile p xs@(x:_) | p x = dropWhile p xs'    -- eager recursion
```

### Why doesn't `map` / `filter` / `take_while` / `flat_map` accept `raise?`?

Because their callbacks fire from inside `@lazy.Lazy` thunks. Thunks are
non-raising by design (see `@lazy/lazy.mbt`): a raising thunk would force
every consumer of every lazy cell to handle the effect, and memoizing
failure forces an awkward choice between "cache the error and re-raise on
every retry" and "retry on every force."

If you need a fallible transform, wrap the result yourself:

```mbt check
///|
test {
  fn maybe_double(x : Int) -> Result[Int, String] {
    if x < 0 {
      Err("negative")
    } else {
      Ok(x * 2)
    }
  }

  let xs = @lazy_list.from_iter([1, 2, -1, 3].iter()).map(maybe_double)
  let results = xs.to_array()
  debug_inspect(
    results,
    content=(
      #|[Ok(2), Ok(4), Err("negative"), Ok(6)]
    ),
  )
}
```

`drop_while` is the one exception — it runs `pred` only during the strict
skip phase, so it accepts `(A) -> Bool raise?` and propagates errors.

### Why no `from_array` / `from_list` / `singleton` / `repeat` / `iterate`?

Each is a one-liner over `from_iter` or `lazy_cons`. We optimize for a
small, memorable API surface: anything that doesn't add capability beyond
the primitives stays out of the package. If a particular helper turns up
repeatedly in user code, we can add it back — the reverse (removing a
public API) is much harder.

### Forced cycles can hang `Debug`

If you deliberately construct a self-referential `lazy_cons` and force it,
`Debug` will loop walking the cached cells. `@list.List`'s `Debug` has the
same property; cycle detection is not provided.
