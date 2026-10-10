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
let test_profile : Profile = Profile(
  valid=RecharSet::char_range(0, 0xFFFF),
  word=RecharSet::char_range('a', 'z'),
  category=c => {
    match c {
      'a'..='z' => Category::word()
      '\n' => Category::newline() + Category::not_word()
      _ => Category::not_word()
    }
  },
)

///|
test "lazy states and transitions are reused" {
  let a = char(RecharSet::char('a'))
  let body = capture(quantifier(a, { min: 0, max: None, mode: Greedy, }))
  let re = compile(
    profile=test_profile,
    seq([start_of_input, body, end_of_input]),
  )
  inspect(re.states.length(), content="0")
  guard re.execute("aaaa", 0) is Some(saved) else { fail("missing match") }
  let state_count = re.states.length()
  let generation = re.generation
  let registers = re.max_registers
  for _ in 0..<20 {
    @test.assert_eq(
      re.execute("aaaa", 0).map(m => m.group(1)),
      Some(Some((0, 4))),
    )
  }
  @test.assert_eq(re.states.length(), state_count)
  @test.assert_eq(re.generation, generation)
  @test.assert_eq(re.max_registers, registers)
  ignore(re.execute("", 0))
  ignore(re.execute("aa", 0))
  // Results own endpoints rather than the mutable register buffer.
  @debug.debug_inspect(saved.group(1), content="Some((0, 4))")
  @debug.debug_inspect(saved.group(0x7FFF_FFFF), content="None")
  @debug.debug_inspect(saved.group(-1), content="None")
}

///|
test "closure generations reset before reusing the zero stamp" {
  let a = char(RecharSet::char('a'))
  let b = char(RecharSet::char('b'))
  let c = char(RecharSet::char('c'))
  let re = compile(profile=test_profile, seq([start_of_input, a, alt([b, c])]))
  ignore(re.execute("ab", 0))
  re.generation = -1
  re.seen.fill(1)
  @debug.debug_inspect(
    re.execute("ac", 0).map(m => m.group(0)),
    content="Some(Some((0, 2)))",
  )
  @test.assert_eq(re.generation > 0, true)
}
