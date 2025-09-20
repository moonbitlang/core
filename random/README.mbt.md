# Random

This is an efficient random number generation function based on the paper [Fast Random Integer Generation in an Interval](https://arxiv.org/abs/1805.10941) by Daniel Lemire, as well as the Golang's `rand/v2` package.

Internally, it uses the `Chacha8` cipher to generate random numbers. It is a cryptographically secure pseudo-random number generator (CSPRNG) that is also very fast.

# Usage

```moonbit
///|
test {
  let r = @random.Rand::new()
  assert_eq(r.uint(limit=10), 7)
  assert_eq(r.uint(limit=10), 0)
  assert_eq(r.uint(limit=10), 5)
  assert_eq(r.int(), 1064320769)
  assert_eq(r.double(), 0.3318940049218405)
  assert_eq(r.int(limit=10), 0)
  assert_eq(r.uint(), 311122750)
  assert_eq(r.int64(), 2043189202271773519)
  assert_eq(r.int64(limit=10), 8)
  assert_eq(r.uint64(), 3951155890335085418)
  let a = [1, 2, 3, 4, 5]
  r.shuffle(a.length(), (i, j) => {
    let t = a[i]
    a[i] = a[j]
    a[j] = t
  })
  assert_eq(a, [2, 1, 4, 3, 5])
}
```
