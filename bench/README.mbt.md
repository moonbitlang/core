# Bench Package Documentation

This package provides benchmarking utilities for measuring the performance of MoonBit code. It includes functions for timing code execution, collecting statistics, and generating performance reports.

## Basic Benchmarking

Use the `single_bench` function to benchmark individual operations:

```moonbit
test "basic benchmarking" {
  fn fibonacci(n : Int) -> Int {
    if n <= 1 { n } else { fibonacci(n - 1) + fibonacci(n - 2) }
  }
  
  // Benchmark a simple computation
  let summary = single_bench(name="fibonacci_10", fn() { 
    ignore(fibonacci(10))
  })
  
  // The benchmark ran successfully (we can't inspect exact timing)
  inspect(summary.to_json().stringify().length() > 0, content="true")
}
```

## Benchmark Collection

Use the `T` type to collect multiple benchmarks:

```moonbit
test "benchmark collection" {
  let bencher = new()
  
  // Add multiple benchmarks to the collection
  bencher.bench(name="array_creation", fn() {
    let arr = Array::new()
    for i in 0..<100 {
      arr.push(i)
    }
  })
  
  bencher.bench(name="array_iteration", fn() {
    let arr = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    let mut sum = 0
    for x in arr {
      sum = sum + x
    }
  })
  
  // Generate benchmark report
  let report = bencher.dump_summaries()
  inspect(report.length() > 0, content="true")
}
```

## Benchmarking Different Algorithms

Compare the performance of different implementations:

```moonbit
test "algorithm comparison" {
  let bencher = new()
  
  // Benchmark linear search
  bencher.bench(name="linear_search", fn() {
    let arr = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    let target = 7
    let mut found = false
    for x in arr {
      if x == target {
        found = true
        break
      }
    }
    ignore(found)
  })
  
  // Benchmark using built-in contains (likely optimized)
  bencher.bench(name="builtin_contains", fn() {
    let arr = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    ignore(arr.contains(7))
  })
  
  let results = bencher.dump_summaries()
  inspect(results.length() > 10, content="true")  // Should have benchmark data
}
```

## Data Structure Benchmarks

Benchmark different data structure operations:

```moonbit
test "data structure benchmarks" {
  let bencher = new()
  
  // Benchmark Array operations
  bencher.bench(name="array_append", fn() {
    let arr = Array::new()
    for i in 0..<50 {
      arr.push(i)
    }
  })
  
  // Benchmark FixedArray access
  bencher.bench(name="fixedarray_access", fn() {
    let arr = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    let mut sum = 0
    for i in 0..<arr.length() {
      sum = sum + arr[i]
    }
    ignore(sum)
  })
  
  let report = bencher.dump_summaries()
  inspect(report.contains("array_append"), content="true")
}
```

## String Operations Benchmarking

Measure string manipulation performance:

```moonbit
test "string benchmarks" {
  let bencher = new()
  
  // Benchmark string concatenation
  bencher.bench(name="string_concat", fn() {
    let mut result = ""
    for i in 0..<20 {
      result = result + "x"
    }
  })
  
  // Benchmark StringBuilder (should be faster)
  bencher.bench(name="stringbuilder", fn() {
    let builder = StringBuilder::new()
    for i in 0..<20 {
      builder.write_string("x")
    }
    ignore(builder.to_string())
  })
  
  let results = bencher.dump_summaries()
  inspect(results.contains("stringbuilder"), content="true")
}
```

## Memory Usage Prevention

Use `keep` to prevent compiler optimizations from eliminating benchmarked code:

```moonbit
test "preventing optimization" {
  let bencher = new()
  
  bencher.bench(name="with_keep", fn() {
    let result = Array::makei(100, fn(i) { i * i })
    // Prevent the compiler from optimizing away the computation
    bencher.keep(result)
  })
  
  let report = bencher.dump_summaries()
  inspect(report.contains("with_keep"), content="true")
}
```

## Iteration Count Control

Control the number of benchmark iterations:

```moonbit
test "iteration control" {
  let bencher = new()
  
  // Run with more iterations for more stable results
  bencher.bench(name="stable_benchmark", fn() {
    let arr = [1, 2, 3, 4, 5]
    let sum = arr.fold(init=0, fn(acc, x) { acc + x })
    ignore(sum)
  }, count=20)
  
  // Run with fewer iterations for quick testing
  bencher.bench(name="quick_benchmark", fn() {
    let mut result = 0
    for i in 0..<1000 {
      result = result + i
    }
    ignore(result)
  }, count=5)
  
  let results = bencher.dump_summaries()
  inspect(results.contains("stable_benchmark"), content="true")
}
```

## Benchmarking Best Practices

### 1. Isolate What You're Measuring

```moonbit
test "isolation example" {
  let bencher = new()
  
  // Good: Measure only the operation of interest
  let data = Array::makei(1000, fn(i) { i })  // Setup outside benchmark
  
  bencher.bench(name="array_sum", fn() {
    let mut sum = 0
    for x in data {
      sum = sum + x
    }
    bencher.keep(sum)  // Prevent optimization
  })
  
  let results = bencher.dump_summaries()
  inspect(results.length() > 0, content="true")
}
```

### 2. Warm Up Before Measuring

```moonbit
test "warmup example" {
  let bencher = new()
  
  fn expensive_operation() -> Int {
    let mut result = 0
    for i in 0..<100 {
      result = result + i * i
    }
    result
  }
  
  // Warm up the function (not measured)
  for _ in 0..<5 {
    ignore(expensive_operation())
  }
  
  // Now benchmark the warmed-up function
  bencher.bench(name="warmed_up", fn() {
    let result = expensive_operation()
    bencher.keep(result)
  })
  
  let report = bencher.dump_summaries()
  inspect(report.contains("warmed_up"), content="true")
}
```

### 3. Use Meaningful Names

```moonbit
test "meaningful names" {
  let bencher = new()
  
  // Good: Descriptive names that explain what's being measured
  bencher.bench(name="hashmap_insert_1000_items", fn() {
    let map = @hashmap.new()
    for i in 0..<1000 {
      map.set(i, i * 2)
    }
    bencher.keep(map)
  })
  
  bencher.bench(name="array_binary_search_sorted_1000", fn() {
    let arr = Array::makei(1000, fn(i) { i })
    let result = arr.contains(500)  // Linear search in this case
    bencher.keep(result)
  })
  
  let results = bencher.dump_summaries()
  inspect(results.contains("hashmap_insert"), content="true")
}
```

## Performance Analysis

The benchmark results include statistical information:

- **Timing measurements**: Microsecond precision timing
- **Statistical analysis**: Median, percentiles, and outlier detection
- **Batch sizing**: Automatic adjustment for stable measurements
- **JSON output**: Machine-readable results for analysis

## Integration with Testing

Benchmarks can be integrated into your testing workflow:

```moonbit
test "performance regression test" {
  let bencher = new()
  
  // Benchmark a critical path
  bencher.bench(name="critical_algorithm", fn() {
    let data = [5, 2, 8, 1, 9, 3, 7, 4, 6]
    let mut sorted = Array::new()
    for x in data {
      sorted.push(x)
    }
    sorted.sort()
    bencher.keep(sorted)
  })
  
  let results = bencher.dump_summaries()
  // In a real scenario, you might parse results and assert performance bounds
  inspect(results.length() > 50, content="true")  // Should have substantial data
}
```

## Common Benchmarking Patterns

1. **Before/After comparisons**: Benchmark code before and after optimizations
2. **Algorithm comparison**: Compare different implementations of the same functionality
3. **Scaling analysis**: Benchmark with different input sizes
4. **Memory vs. speed tradeoffs**: Compare memory-efficient vs. speed-optimized approaches
5. **Platform differences**: Compare performance across different targets (JS, WASM, native)

## Tips for Accurate Benchmarks

- Run benchmarks multiple times and look for consistency
- Be aware of system load and other processes affecting timing
- Use appropriate iteration counts (more for stable results, fewer for quick feedback)
- Measure what matters to your use case
- Consider both average case and worst case performance
- Profile memory usage separately if memory performance is important

The bench package provides essential tools for performance analysis and optimization in MoonBit applications.
