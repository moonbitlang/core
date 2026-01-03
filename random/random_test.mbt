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

///|
test "prng" {
  let r = @random.Rand::new()
  assert_eq(r.uint(limit=10), 7)
  assert_eq(r.uint(limit=10), 0)
  assert_eq(r.uint(limit=10), 5)
  assert_eq(r.int(), 1064320769)
  assert_eq(r.double(), 0.3318940049218405)
  assert_eq(r.int(limit=10), 0)
  assert_eq(r.uint(), 311122750)
  let int64_val = r.int64()
  inspect(int64_val, content="2043189202271773519")
  assert_true(int64_val >= 0L)
  let limit : UInt64 = 1UL << 63
  assert_true(int64_val.reinterpret_as_uint64() < limit)
  assert_eq(r.int64(limit=10), 8)
  assert_eq(r.uint64(), 3951155890335085418)
  let a = [1, 2, 3, 4, 5]
  r.shuffle(a.length(), (i : Int, j : Int) => {
    let t = a[i]
    a[i] = a[j]
    a[j] = t
  })
  assert_eq(a, [2, 1, 4, 3, 5])
}

///|
struct FixedSource {
  mut value : UInt64
}

///|
impl @random.Source for FixedSource with next(self) -> UInt64 {
  let current = self.value
  self.value += 1UL
  current
}

///|
test "Rand::new with generator" {
  let gen : FixedSource = { value: 1UL }
  let rand = @random.Rand::new(generator=gen as &@random.Source)
  inspect(rand.int(limit=10) < 10, content="true")
}

///|
test {
  let random = @random.Rand::new()
  inspect(random.float(), content="0.27378302812576294")
  inspect(random.float(), content="0.4169347286224365")
  inspect(random.float(), content="0.5513989925384521")
  inspect(random.float(), content="0.8607915639877319")
  inspect(random.float(), content="0.10972100496292114")
}

///|
test "panic random with invalid seed length" {
  let short_seed = b"short seed"
  let _ = @random.Rand::chacha8(seed=short_seed)

}

///|
test "panic negative limit in shuffle" {
  let r = @random.Rand::new()
  let arr = [1, 2, 3]
  r.shuffle(-1, (i : Int, j : Int) => {
    let t = arr[i]
    arr[i] = arr[j]
    arr[j] = t
  })
}

///|
test "uint64 modulo bias handling with large limit" {
  let r = @random.Rand::new()
  let limit = 12345678901234567890UL // Large non-power-of-2 number
  let result = r.uint64(limit~)
  inspect(result < limit, content="true")
}

///|
test "bench random" (b : @bench.T) {
  let r = @random.Rand::new()
  b.bench(() => for i in 0..<1000000 {
    let _ = r.uint64(limit=10000000000000000000UL)

  })
}

///|
test "boolean" {
  let result = @random.Rand::new()
  inspect(result.boolean(), content="true")
}
