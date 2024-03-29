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
  counter : Array[Int]
} derive(Show)

/// Create a new coverage counter with the given size.
pub fn CoverageCounter::new(size : Int) -> CoverageCounter {
  { counter: Array::make(size, 0) }
}

/// Increment the specified tracking index.
pub fn CoverageCounter::incr(self : CoverageCounter, idx : Int) -> Unit {
  let counter = self.counter[idx]
  if counter < 0x7fffffff { // prevent overflow
    self.counter[idx] = counter + 1
  }
}

/// Output the contents of this counter in JSON format.
fn CoverageCounter::debug_write(self : CoverageCounter, buf : Buffer) -> Unit {
  buf.write_char('[')
  let mut i = 0
  while i < self.counter.length() {
    if i != 0 {
      buf.write_string(", ")
    }
    self.counter[i].debug_write(buf)
    i += 1
  }
  buf.write_char(']')
}

test "new_counter" {
  let counter = CoverageCounter::new(2)
  let result = counter.to_string()
  // @test.eq(result, "[0, 0]")?
  if result != "[0, 0]" {
    return Err("Expected: [0, 0], got: " + result)
  }
}

test "incr_counter" {
  let counter = CoverageCounter::new(10)
  counter.incr(0)
  counter.incr(9)
  let result = counter.to_string()
  // @test.eq(result, "[1, 0, 0, 0, 0, 0, 0, 0, 0, 1]")?
  if result != "[1, 0, 0, 0, 0, 0, 0, 0, 0, 1]" {
    return Err("Expected: [1, 0, 0, 0, 0, 0, 0, 0, 0, 1], got: " + result)
  }
}

/// The global list of counters currently tracking.
let counters : Ref[List[(String, CoverageCounter)]] = { val: Nil }

/// Add the given counter along its ID to the tracking list.
pub fn track(name : String, counter : CoverageCounter) -> Unit {
  counters.val = Cons((name, counter), counters.val)
}

trait Output {
  output(Self, String) -> Unit
}

type IO Int

fn output(self : IO, content : String) -> Unit {
  ignore(self)
  print(content)
}

fn Output::output(self : Buffer, content : String) -> Unit {
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

  let mut ix = 0
  while ix < s.length() {
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
    ix += 1
  }
}

/// Escape a string using standard C escape sequences and return the escaped string,
/// usually for quoting uses.
///  
/// This method only escapes characters below 0x20 and the following characters:
/// `"`, `'`, `\`.
pub fn escape(s : String) -> String {
  let buf = Buffer::make(s.length())
  escape_to(s, buf)
  buf.to_string()
}

test "backslash escape" {
  let s = "\n\r\t\b\"'\\"
  let expected = "\\n\\r\\t\\b\\\"'\\\\"
  // @test.eq(escape(s), expected)?
  let escape_s = escape(s)
  if escape_s != expected {
    return Err("Expected: " + expected + ", got: " + escape_s)
  }
}

// FIXME: formatting string does not work, this test will be destroyed by formatting
// test "hex escape" {
//   let s = "\x11\x12\x01\x02"
//   let expected = "\\x11\\x12\\x01\\x02"
//   @test.eq(s.escape(), expected)?
// }

fn log(counters : List[(String, CoverageCounter)], io : Output) -> Unit {
  let print = fn { x => io.output(x) }
  let println = fn {
    x => {
      io.output(x)
      io.output("\n")
    }
  }
  print("{ ")
  loop counters, 0 {
    Cons((name, counter), xs), ix => {
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
    Nil, _ => ()
  }
  println("}")
}

test "log" {
  let test_counter_a = CoverageCounter::new(2)
  let test_counter_b = CoverageCounter::new(2)
  test_counter_a.incr(0)
  test_counter_b.incr(1)
  let counters : List[(String, CoverageCounter)] = Cons(
    ("foo/foo", test_counter_a),
    Cons(("foo/bar", test_counter_b), Nil),
  )
  let buf = Buffer::make(1024)
  log(counters, buf)
  let result = buf.to_string()
  let expected =
    #|{ "foo/foo": [1, 0]
    #|, "foo/bar": [0, 1]
    #|}
    #|

  // @test.eq(result, expected)?
  if result != expected {
    return Err("Expected: " + expected + ", got: " + result)
  }
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
  log(counters.val, IO::IO(0))
  println("----- END MOONBIT COVERAGE -----")
}
