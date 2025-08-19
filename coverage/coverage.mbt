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
priv enum CounterList {
  Empty
  More(String, CoverageCounter, CounterList)
}

///|
/// The global list of counters currently tracking.
let counters : Ref[CounterList] = { val: Empty }

///|
/// Add the given counter along its ID to the tracking list.
///
#coverage.skip
pub fn track(name : String, counter : CoverageCounter) -> Unit {
  counters.val = More(name, counter, counters.val)
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
  coverage_log(counters.val, writeln=println)
  println("----- END MOONBIT COVERAGE -----")
  coverage_reset(counters.val) // Reset all counters to avoid double counting
}

///|
fn coverage_reset(counters : CounterList) -> Unit {
  loop counters {
    More(_, CoverageCounter(counter), xs) => {
      for i in 0..<counter.length() {
        counter[i] = 0
      }
      continue xs
    }
    Empty => ()
  }
}

///|
fn coverage_log(counters : CounterList, writeln~ : (String) -> Unit) -> Unit {
  let line_buf = StringBuilder::new()
  let print = x => line_buf.write_string(x)
  let println = x => {
    line_buf.write_string(x)
    writeln(line_buf.to_string())
    line_buf.reset()
  }
  print("{ ")
  loop (counters, 0) {
    (More(name, counter, xs), ix) => {
      if ix != 0 {
        print(", ")
      }
      print(name.escape())
      print(": ")
      let counter_dump = counter.to_string()
      println(counter_dump)
      continue (xs, ix + 1)
    }
    (Empty, _) => ()
  }
  println("}")
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
fn debug_buf_and_writeln() -> (StringBuilder, (String) -> Unit) {
  let buf = StringBuilder::new()
  (buf, s => buf..write_string(s)..write_char('\n'))
}

///|
test "log empty" {
  let counters = Empty
  let (buf, writeln) = debug_buf_and_writeln()
  coverage_log(counters, writeln~)
  inspect(
    buf,
    content=(
      #|{ }
      #|
    ),
  )
}

///|
test "log" {
  let test_counter_a = CoverageCounter::new(2)
  let test_counter_b = CoverageCounter::new(2)
  test_counter_a.incr(0)
  test_counter_b.incr(1)
  let counters : CounterList = More(
    "foo/foo",
    test_counter_a,
    More("foo/bar", test_counter_b, Empty),
  )
  let (buf, writeln) = debug_buf_and_writeln()
  coverage_log(counters, writeln~)
  inspect(
    buf,
    content=(
      #|{ "foo/foo": [1, 0]
      #|, "foo/bar": [0, 1]
      #|}
      #|
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
  let counters : CounterList = More(
    "foo/foo",
    test_counter_a,
    More("foo/bar", test_counter_b, Empty),
  )
  let (buf, writeln) = debug_buf_and_writeln()
  coverage_log(counters, writeln~)
  inspect(
    buf,
    content=(
      #|{ "foo/foo": [1, 0]
      #|, "foo/bar": [0, 1]
      #|}
      #|
    ),
  )
  coverage_reset(counters)
  let (buf, writeln) = debug_buf_and_writeln()
  coverage_log(counters, writeln~)
  inspect(
    buf,
    content=(
      #|{ "foo/foo": [0, 0]
      #|, "foo/bar": [0, 0]
      #|}
      #|
    ),
  )
}

// FIXME: formatting string does not work, this test will be destroyed by formatting
// test "hex escape" {
//   let s = "\x11\x12\x01\x02"
//   let expected = "\\x11\\x12\\x01\\x02"
//   assert_eq(s.@coverage.escape(), expected)?
// }
