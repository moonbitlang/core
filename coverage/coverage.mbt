pub struct CoverageCounter {
  priv counter : Array[Int]
} derive(Show)

fn CoverageCounter::new(size : Int) -> CoverageCounter {
  { counter: Array::make(size, 0) }
}

fn CoverageCounter::incr(self : CoverageCounter, idx : Int) -> Unit {
  let counter = self.counter[idx]
  if counter < 0x7fffffff { // prevent overflow
    self.counter[idx] = counter + 1
  }
}

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

let counters : Ref[List[(String, CoverageCounter)]] = { val: Nil }

pub fn track(name : String, counter : CoverageCounter) -> Unit {
  counters.val = Cons((name, counter), counters.val)
}

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
