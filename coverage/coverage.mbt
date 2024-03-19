/// The `CoverageCounter` structure is used for keeping track of the number of
/// times each chunk of code is executed. It's not very useful outside of 
/// generated code.
pub struct CoverageCounter {
  priv counter : Array[Int]
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
  println("{")
  let mut ix = 0
  loop counters.val {
    Cons((name, counter), xs) => {
      if ix != 0 {
        print(", ")
      }
      print('"')
      print(name.escape())
      print("\": ")
      let counter_dump = counter.to_string()
      println(counter_dump)
      ix += 1
      continue xs
    }
    Nil => break
  }
  println("}")
  println("----- END MOONBIT COVERAGE -----")
}
