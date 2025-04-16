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

// The original code is licensed under both the Apache License, Version 2.0 and the MIT license.
// Please refer to https://github.com/rust-lang/rust/blob/a19472a93e2eecce1477011fa9f7ec49b45ca164/library/test/src/stats.rs

///|
pub struct Summary {
  sum : Double
  min : Double
  max : Double
  mean : Double
  median : Double
  var : Double
  std_dev : Double
  std_dev_pct : Double
  median_abs_dev : Double
  median_abs_dev_pct : Double
  quartiles : (Double, Double, Double)
  iqr : Double
  batch_size : Int
  runs : Int
} derive(ToJson)

///|
fn Summary::new(data : Array[Double], batch_size : Int) -> Summary {
  let sum = sum(data)
  let min = min(data)
  let max = max(data)
  let mean = mean(data)
  let median = median(data)
  let var = var(data)
  let std_dev = std_dev(data)
  let std_dev_pct = std_dev_pct(data)
  let median_abs_dev = median_abs_dev(data)
  let median_abs_dev_pct = median_abs_dev_pct(data)
  let quartiles = quartiles(data)
  let iqr = iqr(data)
  {
    sum,
    min,
    max,
    mean,
    median,
    var,
    std_dev,
    std_dev_pct,
    median_abs_dev,
    median_abs_dev_pct,
    quartiles,
    iqr,
    batch_size,
    runs: data.length(),
  }
}

///|
fn sum(data : Array[Double]) -> Double {
  let mut sum = 0.0
  for i in data {
    sum += i
  }
  sum
}

///|
fn min(data : Array[Double]) -> Double {
  let mut min = data[0]
  for i in data {
    if i < min {
      min = i
    }
  }
  min
}

///|
fn max(data : Array[Double]) -> Double {
  let mut max = data[0]
  for i in data {
    if i > max {
      max = i
    }
  }
  max
}

///|
fn mean(data : Array[Double]) -> Double {
  let sum = sum(data)
  let count = data.length()
  sum / count.to_double()
}

///|
fn median(data : Array[Double]) -> Double {
  percentile(data, 50.0)
}

///|
fn var(data : Array[Double]) -> Double {
  if data.length() < 2 {
    return 0.0
  }
  let mean = mean(data)
  let mut v = 0.0
  for i in data {
    let d = i - mean
    v += d * d
  }
  v / (data.length() - 1).to_double()
}

///|
fn std_dev(data : Array[Double]) -> Double {
  var(data).sqrt()
}

///|
fn std_dev_pct(data : Array[Double]) -> Double {
  let mean = mean(data)
  let std_dev = std_dev(data)
  if mean == 0.0 {
    return 0.0
  }
  std_dev / mean * 100.0
}

///|
fn median_abs_dev(data : Array[Double]) -> Double {
  let med = median(data)
  let abs_devs = data.map(fn(x) { (med - x).abs() })
  // https://en.wikipedia.org/wiki/Median_absolute_deviation
  median(abs_devs) * 1.4826
}

///|
fn median_abs_dev_pct(data : Array[Double]) -> Double {
  let med = median(data)
  let mad = median_abs_dev(data)
  if med == 0.0 {
    return 0.0
  }
  mad / med * 100.0
}

///|
fn quartiles(data : Array[Double]) -> (Double, Double, Double) {
  let sorted = data.copy()
  sorted.sort()
  try {
    let q1 = percentile_of_sorted!(sorted, 25.0)
    let q2 = percentile_of_sorted!(sorted, 50.0)
    let q3 = percentile_of_sorted!(sorted, 75.0)
    (q1, q2, q3)
  } catch {
    _ => panic()
  }
}

///|
fn iqr(data : Array[Double]) -> Double {
  let (q1, _, q3) = quartiles(data)
  q3 - q1
}

///|
fn percentile_of_sorted(data : Array[Double], pct : Double) -> Double! {
  assert_false!(data.is_empty())
  assert_true!(pct >= 0.0 && pct <= 100.0)
  if data.length() == 1 {
    return data[0]
  }
  if pct == 100.0 {
    return data[data.length() - 1]
  }
  let length = (data.length() - 1).to_double()
  let rank = pct / 100 * length
  let lrank = rank.floor()
  let d = rank - lrank
  let n = lrank.to_int()
  let lo = data[n]
  let hi = data[n + 1]
  lo + (hi - lo) * d
}

///|
fn percentile(data : Array[Double], pct : Double) -> Double {
  let sorted = data.copy()
  sorted.sort()
  try {
    percentile_of_sorted!(sorted, pct)
  } catch {
    _ => panic()
  }
}

///|
fn winsorize(data : Array[Double], pct : Double) -> Unit {
  let sorted = data.copy()
  sorted.sort()
  try {
    let lo = percentile_of_sorted!(sorted, pct)
    let hi = percentile_of_sorted!(sorted, 100.0 - pct)
    for i, samp in data {
      if samp > hi {
        data[i] = hi
      } else if samp < lo {
        data[i] = lo
      }
    }
  } catch {
    _ => panic()
  }
}
