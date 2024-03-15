pub struct CoverageCounter {
  priv counter : Array[Int]
}

fn CoverageCounter::new(size : Int) -> CoverageCounter {
  { counter: Array::make(size, 0) }
}

fn CoverageCounter::incr(self : CoverageCounter, idx : Int) -> Unit {
  let counter = self.counter[idx];
  if counter < 0x7fffffff { // prevent overflow
    self.counter[idx] = counter + 1
  }
}

fn CoverageCounter::to_string(self : CoverageCounter) -> String {
  let mut s = "["
  let mut i = 0
  while i < self.counter.length() {
    if i != 0 {
      s += ", "
    }
    s += self.counter[i].to_string()
    i += 1
  }
  s += "]"
  s
}

test "new_counter" {
  let counter = CoverageCounter::new(2)
  let result = counter.to_string()
  if result != "[0, 0]" {
    println(result)
    abort("error")
  }
}

test "incr_counter" {
  let counter = CoverageCounter::new(10)
  counter.incr(0)
  counter.incr(9)
  let result = counter.to_string()
  if result != "[1, 0, 0, 0, 0, 0, 0, 0, 0, 1]" {
    println(result)
    abort("error")
  }
}

let counters : Ref[List[(String, CoverageCounter)]] = { val: Nil }

fn escape_string(s : String) -> String {
  let buf = Buffer::make(s.length())
  let mut ix = 0
  while ix < s.length() {
    let ch = s[ix]
    match ch {
      '\"' | '\'' | '\\' => {
        buf.write_char('\\')
        buf.write_char(ch)
      }
      '\n' => {
        buf.write_char('\\')
        buf.write_char('n')
      }
      _ => {
        buf.write_char(ch)
      }
    }
    ix += 1
  }
  buf.to_string()
}

pub fn track(name : String, counter : CoverageCounter) -> Unit {
  counters.val = Cons((name, counter), counters.val)
}

pub fn end() -> Unit {
  println("----- BEGIN MOONBIT COVERAGE -----")
  println("{")
  let mut ix = 0;
  loop counters.val {
    Cons((name, counter), xs) => {
      if ix != 0 {
        print(", ")
      }
      print('"')
      print(escape_string(name))
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
