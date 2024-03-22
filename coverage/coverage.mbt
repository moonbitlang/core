/// The `CoverageCounter` structure is used for keeping track of the number of
/// times each chunk of code is executed. It's not very useful outside of 
/// generated code.
struct CoverageCounter {
  counter : Array[Int]
} derive(Show)

/// Create a new coverage counter with the given size.
fn CoverageCounter::new(size : Int) -> CoverageCounter {
  { counter: Array::make(size, 0) }
}

/// Increment the specified tracking index.
fn CoverageCounter::incr(self : CoverageCounter, idx : Int) -> Unit {
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
  @assertion.assert_eq(result, "[0, 0]")?
}

test "incr_counter" {
  let counter = CoverageCounter::new(10)
  counter.incr(0)
  counter.incr(9)
  let result = counter.to_string()
  @assertion.assert_eq(result, "[1, 0, 0, 0, 0, 0, 0, 0, 0, 1]")?
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

fn log(counters : List[(String, CoverageCounter)], io : Output) -> Unit {
  let print = fn { x => io.output(x) }
  let println = fn {
    x => {
      io.output(x)
      io.output("\n")
    }
  }
  print("{")
  loop counters, 0 {
    Cons((name, counter), xs), ix => {
      if ix != 0 {
        print(", ")
      }
      print("\"")
      print(name.escape())
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
  // TODO: ziye log to buffer & add test
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
