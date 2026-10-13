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
/// The generation counter that stamps visited nodes must never land on a
/// stamp still stored in the marks. Found in review: after enough transition
/// builds it wrapped to `0`, the value untouched marks start with, so nodes
/// looked visited and a valid match was lost.
test "generation stamps survive counter rollover" {
  let profile = Profile(
    valid=RecharSet::char_range(0, 0xFFFF),
    word=RecharSet::char_range('a', 'z'),
    category=_ => Category::word(),
  )
  // `^(?:(a)|(b))` with a cache that never keeps anything, so every step
  // builds a transition. The `a` branch stays untouched while `b` is used.
  let pat = seq([
    start_of_input,
    alt([
      capture(char(RecharSet::char('a'))),
      capture(char(RecharSet::char('b'))),
    ]),
  ])
  let re = compile(profile~, pat, max_cache_words=1)
  assert_true(re.execute("b", 0) is Some(_))
  for start in [EPOCH_LIMIT - 2, EPOCH_LIMIT - 1, EPOCH_LIMIT, -2, -1] {
    re.epoch = start
    assert_true(re.execute("x", 0) is None)
    assert_true(re.execute("a", 0) is Some(m) && m.group(1) == Some((0, 1)))
    assert_true(re.execute("b", 0) is Some(m) && m.group(2) == Some((0, 1)))
    assert_true(re.epoch > 0 && re.epoch <= EPOCH_LIMIT)
  }
}
