// Copyright 2024 International Digital Economy Academy
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

/// The `CoverageCounter` structure is used for keeping track of the number of
/// times each chunk of code is executed. It's not very useful outside of
/// generated code.
struct CoverageCounter {
  counter : FixedArray[UInt]
}

/// Create a new coverage counter with the given size.
///
/// @coverage.skip 
pub fn CoverageCounter::new(size : Int) -> CoverageCounter {
  { counter: FixedArray::make(size, 0) }
}

/// Increment the specified tracking index.
///
/// @coverage.skip 
pub fn CoverageCounter::incr(self : CoverageCounter, idx : Int) -> Unit {
  let counter = self.counter[idx]
  self.counter[idx] = counter + 1
}

pub impl Show for CoverageCounter with output(self, logger) {
  logger.write_char('[')
  for i = 0; i < self.counter.length(); i = i + 1 {
    if i != 0 {
      logger.write_string(", ")
    }
    Show::output(self.counter[i], logger)
  }
  logger.write_char(']')
}

pub fn to_string(self : CoverageCounter) -> String {
  Show::to_string(self)
}

priv enum MList[T] {
  MNil
  MCons(T, MList[T])
}

/// The global list of counters currently tracking.
let counters : Ref[MList[(String, CoverageCounter)]] = { val: MNil }

/// Add the given counter along its ID to the tracking list.
///
/// @coverage.skip
pub fn track(name : String, counter : CoverageCounter) -> Unit {
  counters.val = MCons((name, counter), counters.val)
}

trait Output {
  output(Self, String) -> Unit
}

priv type StringBuffer Array[String]

impl Output for StringBuffer with output(self : StringBuffer, content : String) -> Unit {
  self.0.push(content)
}

impl Output for Buffer with output(self, content) -> Unit {
  self.write_string(content)
}

// TODO: This escape function should belong to the String package, but is
// not mature enough, so it's left here temporarily.
/// Escape a string using standard JSON escape sequences to the given buffer,
/// usually for quoting uses.
///
/// This method only escapes characters below 0x20 and the following characters:
/// `"`, `'`, `\`.
fn escape_to(s : String, buf : Buffer) -> Unit {
  fn write_escaped_ch(ch : Char) -> Unit {
    buf.write_char('\\')
    buf.write_char(ch)
  }

  fn to_hex_digit(i : Int) -> Char {
    if i < 10 {
      Char::from_int('0'.to_int() + i)
    } else {
      Char::from_int('a'.to_int() + (i - 10))
    }
  }

  for ix = 0; ix < s.length(); ix = ix + 1 {
    let ch = s[ix]
    match ch {
      '"' | '\\' => write_escaped_ch(ch)
      '\n' => write_escaped_ch('n')
      '\r' => write_escaped_ch('r')
      '\b' => write_escaped_ch('b')
      '\t' => write_escaped_ch('t')
      _ =>
        if ch.to_int() < 0x20 {
          buf.write_string("\\u00")
          let ich = ch.to_int()
          buf.write_char(to_hex_digit(ich / 16))
          buf.write_char(to_hex_digit(ich % 16))
        } else {
          buf.write_char(ch)
        }
    }
  }
}

/// Escape a string using standard C escape sequences and return the escaped string,
/// usually for quoting uses.
///
/// This method only escapes characters below 0x20 and the following characters:
/// `"`, `'`, `\`.
pub fn escape(s : String) -> String {
  let buf = Buffer::new(size_hint=s.length())
  escape_to(s, buf)
  buf.to_string()
}

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
pub fn end() -> Unit {
  println("----- BEGIN MOONBIT COVERAGE -----")
  let sbuf = StringBuffer::StringBuffer([])
  coverage_log(counters.val, sbuf)
  let line_buf = Buffer::new()
  for i = 0; i < sbuf.0.length(); i = i + 1 {
    let str = sbuf.0[i]
    let mut start = 0
    for j = 0; j < str.length(); j = j + 1 {
      if str[j] == '\n' {
        line_buf.write_sub_string(str, start, j)
        println(line_buf.to_string())
        line_buf.reset()
        start = j + 1
      }
    }
    if start < str.length() {
      line_buf.write_sub_string(str, start, str.length())
    }
  }
  let trailing_line = line_buf.to_string()
  if trailing_line.length() > 0 {
    println(trailing_line)
  }
  println("----- END MOONBIT COVERAGE -----")
}

fn coverage_log(
  counters : MList[(String, CoverageCounter)],
  io : Output
) -> Unit {
  let print = fn { x => io.output(x) }
  let println = fn {
    x => {
      io.output(x)
      io.output("\n")
    }
  }
  print("{ ")
  loop counters, 0 {
    MCons((name, counter), xs), ix => {
      if ix != 0 {
        print(", ")
      }
      print("\"")
      print(escape(name))
      print("\": ")
      let counter_dump = counter.to_string()
      println(counter_dump)
      continue xs, ix + 1
    }
    MNil, _ => ()
  }
  print("}")
}

test "new_counter" {
  let counter = CoverageCounter::new(2)
  let result = counter.to_string()
  // @test.eq(result, "[0, 0]")?
  if result != "[0, 0]" {
    fail!("Expected: [0, 0], got: " + result)
  }
}

test "incr_counter" {
  let counter = CoverageCounter::new(10)
  counter.incr(0)
  counter.incr(9)
  let result = counter.to_string()
  // @test.eq(result, "[1, 0, 0, 0, 0, 0, 0, 0, 0, 1]")?
  if result != "[1, 0, 0, 0, 0, 0, 0, 0, 0, 1]" {
    fail!("Expected: [1, 0, 0, 0, 0, 0, 0, 0, 0, 1], got: " + result)
  }
}

test "escape_to" {
  let buf = Buffer::new(size_hint=10)
  escape_to("\\n\\r\\t\\b\\\"'\\\\", buf)
  let escaped_string = buf.to_string()
  if escaped_string != "\\\\n\\\\r\\\\t\\\\b\\\\\\\"'\\\\\\\\" {
    fail!("escaped_string: \(escaped_string)")
  }
}

test "escape_to_unicode" {
  let buf = Buffer::new(size_hint=10)
  escape_to("\u0010\u001f", buf)
  let escaped_string = buf.to_string()
  if escaped_string != "\\u0010\\u001f" {
    fail!("escaped_string: \(escaped_string)")
  }
}

test "log" {
  let test_counter_a = CoverageCounter::new(2)
  let test_counter_b = CoverageCounter::new(2)
  test_counter_a.incr(0)
  test_counter_b.incr(1)
  let counters : MList[(String, CoverageCounter)] = MCons(
    ("foo/foo", test_counter_a),
    MCons(("foo/bar", test_counter_b), MNil),
  )
  let buf = Buffer::new(size_hint=1024)
  coverage_log(counters, buf)
  inspect!(
    buf,
    content=
      #|{ "foo/foo": [1, 0]
      #|, "foo/bar": [0, 1]
      #|}
    ,
  )
}

test "backslash escape" {
  let s = "\n\r\t\b\"'\\"
  let expected = "\\n\\r\\t\\b\\\"'\\\\"
  // @test.eq(@coverage.escape(s), expected)?
  let escape_s = escape(s)
  if escape_s != expected {
    fail!("Expected: " + expected + ", got: " + escape_s)
  }
}

// FIXME: formatting string does not work, this test will be destroyed by formatting
// test "hex escape" {
//   let s = "\x11\x12\x01\x02"
//   let expected = "\\x11\\x12\\x01\\x02"
//   @test.eq(s.@coverage.escape(), expected)?
// }
