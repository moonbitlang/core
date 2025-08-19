// Copyright 2025 International Digital Economy Academy
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
/// The `CoverageCounter` structure is used for keeping track of the number of
/// times each chunk of code is executed. It's not very useful outside of
/// generated code.
struct CoverageCounter(FixedArray[UInt])

///|
/// Create a new coverage counter with the given size.
///
#coverage.skip
pub fn CoverageCounter::new(size : Int) -> CoverageCounter {
  CoverageCounter(FixedArray::make(size, 0))
}

///|
/// Increment the specified tracking index.
///
#coverage.skip
pub fn CoverageCounter::incr(self : CoverageCounter, idx : Int) -> Unit {
  let CoverageCounter(self) = self
  self.unsafe_set(idx, self.unsafe_get(idx) + 1)
}

///|
pub impl Show for CoverageCounter with output(self, logger) {
  let CoverageCounter(self) = self
  logger.write_char('[')
  for i in 0..<self.length() {
    if i != 0 {
      logger.write_string(", ")
    }
    Show::output(self[i], logger)
  }
  logger.write_char(']')
}

///|
priv enum MList[T] {
  MNil
  MCons(T, MList[T])
}

///|
/// The global list of counters currently tracking.
let counters : Ref[MList[(String, CoverageCounter)]] = { val: MNil }

///|
/// Add the given counter along its ID to the tracking list.
///
#coverage.skip
pub fn track(name : String, counter : CoverageCounter) -> Unit {
  counters.val = MCons((name, counter), counters.val)
}

///|
priv trait Output {
  output(Self, String) -> Unit
}

///|
priv struct StringBuffer(Array[String])

///|
impl Output for StringBuffer with output(self : StringBuffer, content : String) -> Unit {
  let StringBuffer(self) = self
  self.push(content)
}

///|
impl Output for StringBuilder with output(self, content) -> Unit {
  self.write_string(content)
}

///|
/// Output the counters to stdout for coverage report usages. The counter data
/// is printed as a map of `{ counter_id: counter_contents }`, enclosed between
/// a pair of delimiters.
///
/// An example output of this function is like the following:
///
/// ```plaintext
/// ----- BEGIN MOONBIT COVERAGE -----
/// {
/// "foo/foo": [1, 2, 3, 4]
/// , "foo/bar": [5, 6, 7, 8]
/// }
/// ----- END MOONBIT COVERAGE -----
/// ```
#coverage.skip
pub fn end() -> Unit {
  println("----- BEGIN MOONBIT COVERAGE -----")
  let sbuf = StringBuffer::StringBuffer([])
  coverage_log(counters.val, sbuf)
  let line_buf = StringBuilder::new()
  for i in 0..<sbuf.0.length() {
    let str = sbuf.0[i]
    let mut start = 0
    for j in 0..<str.length() {
      if str.unsafe_charcode_at(j) == '\n' {
        line_buf.write_substring(str, start, j)
        println(line_buf.to_string())
        line_buf.reset()
        start = j + 1
      }
    }
    if start < str.length() {
      line_buf.write_substring(str, start, str.length())
    }
  }
  let trailing_line = line_buf.to_string()
  if trailing_line.length() > 0 {
    println(trailing_line)
  }
  println("----- END MOONBIT COVERAGE -----")
  coverage_reset(counters.val) // Reset all counters to avoid double counting
}

///|
fn coverage_reset(counters : MList[(String, CoverageCounter)]) -> Unit {
  loop counters {
    MCons((_, CoverageCounter(counter)), xs) => {
      for i in 0..<counter.length() {
        counter[i] = 0
      }
      continue xs
    }
    MNil => ()
  }
}

///|
fn coverage_log(
  counters : MList[(String, CoverageCounter)],
  io : &Output,
) -> Unit {
  let print = x => io.output(x)
  let println = x => {
    io.output(x)
    io.output("\n")
  }
  print("{ ")
  loop (counters, 0) {
    (MCons((name, counter), xs), ix) => {
      if ix != 0 {
        print(", ")
      }
      print(name.escape())
      print(": ")
      let counter_dump = counter.to_string()
      println(counter_dump)
      continue (xs, ix + 1)
    }
    (MNil, _) => ()
  }
  print("}")
}

///|
test "new_counter" {
  let counter = CoverageCounter::new(2)
  inspect(counter.to_string(), content="[0, 0]")
}

///|
test "incr_counter" {
  let counter = CoverageCounter::new(10)
  counter.incr(0)
  counter.incr(9)
  inspect(counter.to_string(), content="[1, 0, 0, 0, 0, 0, 0, 0, 0, 1]")
}

///|
test "log" {
  let test_counter_a = CoverageCounter::new(2)
  let test_counter_b = CoverageCounter::new(2)
  test_counter_a.incr(0)
  test_counter_b.incr(1)
  let counters : MList[(String, CoverageCounter)] = MCons(
    ("foo/foo", test_counter_a),
    MCons(("foo/bar", test_counter_b), MNil),
  )
  let buf = StringBuilder::new(size_hint=1024)
  coverage_log(counters, buf)
  inspect(
    buf,
    content=(
      #|{ "foo/foo": [1, 0]
      #|, "foo/bar": [0, 1]
      #|}
    ),
  )
}

///|
test "backslash escape" {
  let s = "\n\r\t\b\"'\\"
  inspect(s.escape(), content="\"\\n\\r\\t\\b\\\"'\\\\\"")
}

///|
test "reset" {
  let test_counter_a = CoverageCounter::new(2)
  let test_counter_b = CoverageCounter::new(2)
  test_counter_a.incr(0)
  test_counter_b.incr(1)
  let counters : MList[(String, CoverageCounter)] = MCons(
    ("foo/foo", test_counter_a),
    MCons(("foo/bar", test_counter_b), MNil),
  )
  let buf = StringBuilder::new(size_hint=1024)
  coverage_log(counters, buf)
  inspect(
    buf,
    content=(
      #|{ "foo/foo": [1, 0]
      #|, "foo/bar": [0, 1]
      #|}
    ),
  )
  coverage_reset(counters)
  let buf = StringBuilder::new(size_hint=1024)
  coverage_log(counters, buf)
  inspect(
    buf,
    content=(
      #|{ "foo/foo": [0, 0]
      #|, "foo/bar": [0, 0]
      #|}
    ),
  )
}

// FIXME: formatting string does not work, this test will be destroyed by formatting
// test "hex escape" {
//   let s = "\x11\x12\x01\x02"
//   let expected = "\\x11\\x12\\x01\\x02"
//   assert_eq(s.@coverage.escape(), expected)?
// }
