// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Algebraic-law property sweep for the immutable cons list. Where a law
// could hide a systematic bug that cancels out on both sides (map, fold,
// filter, sort, flat_map, iteration order), the reference side is computed
// with `Array` instead of the list itself.

///|
test "quickcheck: rev is an involution and anti-distributes over concat" {
  @quickcheck.check(
    (input : (@list.List[Int], @list.List[Int])) => {
      let (xs, ys) = input
      guard xs.rev().rev() == xs else { return false }
      guard (xs + ys).rev() == ys.rev() + xs.rev() else { return false }
      // Cross-check against the Array reference so a bug shared by both
      // sides of the laws above cannot cancel out.
      xs.rev().to_array() == xs.to_array().rev()
    },
    count=200,
  )
}

///|
test "quickcheck: concat is a monoid with Empty as identity" {
  @quickcheck.check(
    (input : (@list.List[Int], @list.List[Int], @list.List[Int])) => {
      let (xs, ys, zs) = input
      let empty : @list.List[Int] = @list.empty()
      guard xs + ys + zs == xs + (ys + zs) else { return false }
      guard xs + empty == xs && empty + xs == xs else { return false }
      guard (xs + ys).length() == xs.length() + ys.length() else {
        return false
      }
      // Array reference: concat is really juxtaposition of the contents.
      (xs + ys).to_array() == xs.to_array() + ys.to_array()
    },
    count=200,
  )
}

///|
test "quickcheck: take(n) ++ drop(n) partitions for any n, including out-of-range" {
  @quickcheck.check(
    (input : (@list.List[Int], Int)) => {
      let (xs, n) = input
      // `n` ranges over arbitrary Ints: negative (clamped to taking
      // nothing), zero, in range, and beyond the length (clamped to
      // taking everything).
      guard xs.take(n) + xs.drop(n) == xs else { return false }
      let len = xs.length()
      let clamped = if n < 0 { 0 } else if n > len { len } else { n }
      xs.take(n).length() == clamped && xs.drop(n).length() == len - clamped
    },
    count=300,
  )
}

///|
test "quickcheck: take_while(p) ++ drop_while(p) partitions and respects p" {
  @quickcheck.check(
    (xs : @list.List[Int]) => {
      let p = (x : Int) => x % 3 != 0
      let prefix = xs.take_while(p)
      let rest = xs.drop_while(p)
      guard prefix + rest == xs else { return false }
      guard prefix.all(p) else { return false }
      match rest.head() {
        Some(x) => !p(x)
        None => true
      }
    },
    count=200,
  )
}

///|
test "quickcheck: map preserves length, fuses under composition, matches Array map" {
  @quickcheck.check(
    (xs : @list.List[Int]) => {
      let f = (x : Int) => x * 2 + 1
      let g = (x : Int) => x - 7
      guard xs.map(f).length() == xs.length() else { return false }
      guard xs.map(f).map(g) == xs.map(x => g(f(x))) else { return false }
      // rev_map is map through the mirror.
      guard xs.rev_map(f) == xs.map(f).rev() else { return false }
      // Array reference kills any bug shared by both maps above.
      xs.map(f).to_array() == xs.to_array().map(f)
    },
    count=200,
  )
}

///|
test "quickcheck: fold agrees with an Array loop and relates to rev" {
  @quickcheck.check(
    (xs : @list.List[Int]) => {
      // Non-commutative accumulator so order mistakes cannot cancel.
      let step = (acc : String, x : Int) => acc + x.to_string() + ";"
      let mut expected = ""
      for x in xs.to_array() {
        expected = step(expected, x)
      }
      guard xs.fold(init="", step) == expected else { return false }
      // Folding the reversed list is folding the reversed array.
      let mut expected_rev = ""
      for x in xs.to_array().rev() {
        expected_rev = step(expected_rev, x)
      }
      guard xs.rev().fold(init="", step) == expected_rev else { return false }
      // Numeric sum against the Array reference.
      let mut sum = 0
      for x in xs.to_array() {
        sum += x
      }
      xs.fold(init=0, (a, b) => a + b) == sum
    },
    count=200,
  )
}

///|
test "quickcheck: filter satisfies its predicate and filter_map fuses filter+map" {
  @quickcheck.check(
    (xs : @list.List[Int]) => {
      let p = (x : Int) => x % 2 == 0
      let f = (x : Int) => x / 2
      guard xs.filter(p).all(p) else { return false }
      // Array reference for the kept contents, in order.
      guard xs.filter(p).to_array() == xs.to_array().filter(p) else {
        return false
      }
      // A guarded-Some filter_map is filter followed by map.
      xs.filter_map(x => if p(x) { Some(f(x)) } else { None }) ==
      xs.filter(p).map(f)
    },
    count=200,
  )
}

///|
test "quickcheck: zip truncates to the shorter list and unzip undoes it" {
  @quickcheck.check(
    (input : (@list.List[Int], @list.List[Int])) => {
      let (xs, ys) = input
      let zipped = @list.zip(xs, ys)
      let min_len = if xs.length() < ys.length() {
        xs.length()
      } else {
        ys.length()
      }
      guard zipped.length() == min_len else { return false }
      let (as_, bs) = zipped.unzip()
      as_ == xs.take(min_len) && bs == ys.take(min_len)
    },
    count=200,
  )
}

///|
test "quickcheck: sort produces an ordered permutation matching Array sort" {
  @quickcheck.check(
    (xs : @list.List[Int]) => {
      // Squeeze into 8 values so duplicate-heavy inputs are the norm.
      let xs = xs.map(x => x % 8)
      let sorted = xs.sort()
      guard sorted.length() == xs.length() else { return false }
      // Pairwise ordered.
      let arr = sorted.to_array()
      for i in 1..<arr.length() {
        guard arr[i - 1] <= arr[i] else { return false }
      }
      // Permutation of the input, and identical to the Array reference sort.
      let expected = xs.to_array()
      expected.sort()
      arr == expected
    },
    count=300,
  )
}

///|
test "quickcheck: Array and Iter roundtrips are identities" {
  @quickcheck.check(
    (input : (@list.List[Int], Array[Int])) => {
      let (xs, arr) = input
      guard @list.List(xs.to_array()) == xs else { return false }
      guard @list.List(arr).to_array() == arr else { return false }
      guard @list.from_iter(xs.iter()) == xs else { return false }
      guard @list.from_iter_rev(xs.iter()) == xs.rev() else { return false }
      // The iterator yields exactly the Array contents, in order.
      xs.iter().to_array() == xs.to_array()
    },
    count=200,
  )
}

///|
test "quickcheck: flat_map agrees with an Array reference and flatten" {
  @quickcheck.check(
    (xs : @list.List[Int]) => {
      let f = (x : Int) => @list.List([x, x + 1, x * 2])
      let expected : Array[Int] = []
      for x in xs.to_array() {
        expected.push(x)
        expected.push(x + 1)
        expected.push(x * 2)
      }
      guard xs.flat_map(f).to_array() == expected else { return false }
      // flat_map is map-then-flatten.
      xs.flat_map(f) == xs.map(f).flatten()
    },
    count=200,
  )
}

///|
test "quickcheck: intersperse matches an Array reference" {
  @quickcheck.check(
    (xs : @list.List[Int]) => {
      let sep = -1
      let result = xs.intersperse(sep)
      let expected : Array[Int] = []
      for i, x in xs.to_array() {
        if i > 0 {
          expected.push(sep)
        }
        expected.push(x)
      }
      guard result.to_array() == expected else { return false }
      result.length() == (if xs.is_empty() { 0 } else { 2 * xs.length() - 1 })
    },
    count=200,
  )
}

///|
test "quickcheck: element queries agree with the Array reference" {
  @quickcheck.check(
    (input : (@list.List[Int], Int)) => {
      let (xs, i) = input
      let arr = xs.to_array()
      guard xs.head() == arr.get(0) else { return false }
      guard xs.last() == arr.get(arr.length() - 1) else { return false }
      guard xs.nth(i) == arr.get(i) else { return false }
      let p = (x : Int) => x % 5 == 0
      guard xs.find(p) == arr.iter().find_first(p) else { return false }
      let mut arr_all = true
      let mut arr_any = false
      for x in arr {
        arr_all = arr_all && p(x)
        arr_any = arr_any || p(x)
      }
      xs.all(p) == arr_all && xs.any(p) == arr_any
    },
    count=200,
  )
}
