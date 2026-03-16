///|
#valtype
priv struct LoadedFile {
  path : String
  content : String
  lines : Array[StringView]
}

///|
fn usage(bin : String) -> String {
  ["Usage: \{bin} "].join("\n")
}

///|
fn load_file(path : String) -> LoadedFile {
  let content = read_file_to_string(path) catch {
    err => abort("failed to read '\{path}': \{err.to_string()}")
  }
  let lines = content[:].split("\n").collect()
  { path, content, lines }
}

///|
fn copy_only_checksum(lhs : LoadedFile, rhs : LoadedFile) -> Int {
  let lhs_copy = lhs.lines.copy()
  let rhs_copy = rhs.lines.copy()
  lhs_copy.length() + rhs_copy.length()
}

///|
fn diff_checksum(lhs : LoadedFile, rhs : LoadedFile) -> Int {
  let lhs_copy = lhs.lines.copy()
  let rhs_copy = rhs.lines.copy()
  let edits = @diff.diff(old=lhs_copy.mut_view(), new=rhs_copy.mut_view())
  let mut checksum = edits.length()
  for edit in edits {
    match edit {
      @diff.Delete(old_len~, ..) => checksum += old_len * 3 + 1
      @diff.Insert(new_len~, ..) => checksum += new_len * 5 + 2
      @diff.Equal(len~, ..) => checksum += len * 7 + 3
    }
  }
  checksum
}

///|
fn measure(samples : Int, f : () -> Int) -> (Array[Double], Int) {
  let timings = Array::new(capacity=samples)
  let mut checksum = 0
  for _ in 0..<samples {
    let start = @bench.monotonic_clock_start()
    checksum += f()
    timings.push(@bench.monotonic_clock_end(start))
  }
  (timings, checksum)
}

///|
fn mean(xs : Array[Double]) -> Double {
  for x in xs; sum = 0.0 {
    continue sum + x
  } nobreak {
    sum / xs.length().to_double()
  }
}

///|
fn min(xs : Array[Double]) -> Double {
  let mut result = xs[0]
  for i in 1..<xs.length() {
    if xs[i] < result {
      result = xs[i]
    }
  }
  result
}

///|
fn max(xs : Array[Double]) -> Double {
  let mut result = xs[0]
  for i in 1..<xs.length() {
    if xs[i] > result {
      result = xs[i]
    }
  }
  result
}

///|
fn round3(x : Double) -> Double {
  (x * 1000.0).round() / 1000.0
}

///|
fn format_ms(us : Double) -> String {
  "\{round3(us / 1000.0)}"
}

///|
fn format_sample_list(us_samples : Array[Double]) -> String {
  "[" + us_samples.map(format_ms).join(", ") + "] ms"
}

///|
fn print_summary(name : String, us_samples : Array[Double]) -> Unit {
  println("\{name} samples: \{format_sample_list(us_samples)}")
  println(
    "\{name} mean/min/max: \{format_ms(mean(us_samples))} / \{format_ms(min(us_samples))} / \{format_ms(max(us_samples))} ms",
  )
}

///|
fn main {
  let args = @env.args()
  let bin = args[0]
  if args.length() > 4 {
    println(usage(bin))
    abort("too many arguments")
  }

  let old_path = "diff/perf/huge_cpp_1.cpp"
  let new_path = "diff/perf/huge_cpp_2.cpp"
  let samples = 20

  let lhs = load_file(old_path)
  let rhs = load_file(new_path)

  println("Benchmark target: moonbitlang/core/diff Myers diff")
  println("old: \{lhs.path} (\{lhs.lines.length()} lines)")
  println("new: \{rhs.path} (\{rhs.lines.length()} lines)")
  println("bytes: \{lhs.content.length()} / \{rhs.content.length()}")
  println("samples: \{samples}")

  ignore(copy_only_checksum(lhs, rhs))
  let warmup_checksum = diff_checksum(lhs, rhs)
  println("warmup diff checksum: \{warmup_checksum}")

  let (copy_samples, copy_checksum_sum) = measure(samples, () => {
    copy_only_checksum(lhs, rhs)
  })
  let (diff_samples, diff_checksum_sum) = measure(samples, () => {
    diff_checksum(lhs, rhs)
  })

  let mean_copy = mean(copy_samples)
  let mean_total = mean(diff_samples)
  let estimated_diff = if mean_total > mean_copy {
    mean_total - mean_copy
  } else {
    0.0
  }

  print_summary("copy-only", copy_samples)
  print_summary("copy+diff", diff_samples)
  println("estimated diff mean: \{format_ms(estimated_diff)} ms")
  println("copy checksum sum: \{copy_checksum_sum}")
  println("diff checksum sum: \{diff_checksum_sum}")
}
