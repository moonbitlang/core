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

// The three shapes that decided the tail representation, kept runnable so
// the trade-off can be re-measured instead of re-argued:
//
//   * `build and traverse` is the ordinary path, one tail allocated per
//     element. It is why `Tail` subsumes `@lazy.Lazy` rather than wrapping
//     one — a wrapper adds a box and a dispatch to every cell here, which
//     measured ~30% on this benchmark.
//   * `left-nested concat` is the shape from #4066: with a recursive
//     forcing path it overflows the stack rather than running slowly.
//   * `concat while consuming` is why the pending sequence is a catenable
//     tree — a flat list copies the whole backlog on every step.

///|
let concat_bench_len : Int = 2048

///|
fn bench_left_nested(depth : Int) -> @lazy_list.LazyList[Int] {
  let mut acc : @lazy_list.LazyList[Int] = @lazy_list.empty()
  for i in 0..<depth {
    acc = acc.concat(@lazy_list.from_iter([|i|]))
  }
  acc
}

///|
test "bench LazyList build and traverse n=2048" (it : @bench.T) {
  let source = Array::makei(concat_bench_len, i => i)
  it.bench(fn() {
    let xs = @lazy_list.from_iter(source.iter())
    it.keep(xs.iter().count())
  })
}

///|
test "bench LazyList re-traverse a forced list n=2048" (it : @bench.T) {
  let xs = @lazy_list.from_iter(Array::makei(concat_bench_len, i => i).iter())
  it.keep(xs.iter().count())
  // Every cell is cached now, so this measures the walk alone.
  it.bench(fn() { it.keep(xs.iter().count()) })
}

///|
test "bench LazyList left-nested concat, build only n=2048" (it : @bench.T) {
  it.bench(fn() { it.keep(bench_left_nested(concat_bench_len).is_empty()) })
}

///|
test "bench LazyList left-nested concat, build and traverse n=2048" (
  it : @bench.T,
) {
  it.bench(fn() { it.keep(bench_left_nested(concat_bench_len).iter().count()) })
}

///|
test "bench LazyList concat while consuming n=2048" (it : @bench.T) {
  let source = Array::makei(concat_bench_len + 1, i => i)
  it.bench(fn() {
    let mut cur = @lazy_list.from_iter(source.iter())
    for i in 0..<concat_bench_len {
      cur = cur.concat(@lazy_list.from_iter([|i|]))
      cur = cur.tail().unwrap()
    }
    it.keep(cur.head())
  })
}
