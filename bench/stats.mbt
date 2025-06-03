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
struct Summary {
  name : String?
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
fn Summary::new(
  name? : String,
  sorted_data~ : Array[Double],
  batch_size : Int
) -> Summary {
  let sum = sum(sorted_data)
  let min = min(sorted_data~)
  let max = max(sorted_data~)
  let mean = mean(sorted_data, sum~)
  let median = median(sorted_data~)
  let var = var(sorted_data, mean~)
  let std_dev = std_dev(var~)
  let std_dev_pct = std_dev_pct(mean~, std_dev~)
  let median_abs_dev = median_abs_dev(sorted_data, med=median)
  let median_abs_dev_pct = median_abs_dev_pct(med=median, mad=median_abs_dev)
  let quartiles = quartiles(sorted_data~)
  let iqr = iqr(quartiles~)
  {
    name,
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
    runs: sorted_data.length(),
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
fn min(sorted_data~ : Array[Double]) -> Double {
  sorted_data[0]
}

///|
fn max(sorted_data~ : Array[Double]) -> Double {
  sorted_data[sorted_data.length() - 1]
}

///|
fn mean(data : Array[Double], sum~ : Double) -> Double {
  let count = data.length()
  sum / count.to_double()
}

///|
fn median(sorted_data~ : Array[Double]) -> Double {
  percentile(sorted_data~, pct=50.0)
}

///|
fn var(data : Array[Double], mean~ : Double) -> Double {
  if data.length() < 2 {
    return 0.0
  }
  let mut v = 0.0
  for i in data {
    let d = i - mean
    v += d * d
  }
  v / (data.length() - 1).to_double()
}

///|
fn std_dev(var~ : Double) -> Double {
  var.sqrt()
}

///|
fn std_dev_pct(mean~ : Double, std_dev~ : Double) -> Double {
  if mean == 0.0 {
    return 0.0
  }
  std_dev / mean * 100.0
}

///|
fn median_abs_dev(data : Array[Double], med~ : Double) -> Double {
  let abs_devs = data.map(fn(x) { (med - x).abs() })
  abs_devs.sort()
  // https://en.wikipedia.org/wiki/Median_absolute_deviation
  median(sorted_data=abs_devs) * 1.4826
}

///|
fn median_abs_dev_pct(med~ : Double, mad~ : Double) -> Double {
  if med == 0.0 {
    return 0.0
  }
  mad / med * 100.0
}

///|
fn quartiles(sorted_data~ : Array[Double]) -> (Double, Double, Double) {
  let q1 = percentile(sorted_data~, pct=25.0)
  let q2 = percentile(sorted_data~, pct=50.0)
  let q3 = percentile(sorted_data~, pct=75.0)
  (q1, q2, q3)
}

///|
fn iqr(quartiles~ : (Double, Double, Double)) -> Double {
  let (q1, _, q3) = quartiles
  q3 - q1
}

///|
fn percentile(sorted_data~ : Array[Double], pct~ : Double) -> Double {
  guard sorted_data.length() > 0
  guard pct >= 0.0 && pct <= 100.0
  if sorted_data.length() == 1 {
    return sorted_data[0]
  }
  if pct == 100.0 {
    return sorted_data[sorted_data.length() - 1]
  }
  let length = (sorted_data.length() - 1).to_double()
  let rank = pct / 100 * length
  let lrank = rank.floor()
  let d = rank - lrank
  let n = lrank.to_int()
  let lo = sorted_data[n]
  let hi = sorted_data[n + 1]
  lo + (hi - lo) * d
}

///|
fn winsorize(sorted_data~ : Array[Double], pct : Double) -> Unit {
  let lo = percentile(sorted_data~, pct~)
  let hi = percentile(sorted_data~, pct=100.0 - pct)
  for i, samp in sorted_data {
    if samp > hi {
      sorted_data[i] = hi
    } else if samp < lo {
      sorted_data[i] = lo
    }
  }
}

///|
test {
  let data = [1.1, 21.4, 2.2, 3.3, 4.5, 12.5, 33.3, 14.4]
  data.sort()
  let summary = Summary::new(sorted_data=data, 3)
  assert_true(summary.sum.is_close(92.7))
  assert_true(summary.min.is_close(1.1))
  assert_true(summary.max.is_close(33.3))
  assert_true(summary.mean.is_close(11.5875))
  assert_true(summary.median.is_close(8.5))
  assert_true(summary.var.is_close(127.64125))
  assert_true(summary.std_dev.is_close(11.297842714430043))
  assert_true(summary.std_dev_pct.is_close(97.50026075020534))
  assert_true(summary.median_abs_dev.is_close(9.04386))
  assert_true(summary.median_abs_dev_pct.is_close(106.39835294117646))
  let (q1, q2, q3) = summary.quartiles
  assert_true(q1.is_close(3.025))
  assert_true(q2.is_close(8.5))
  assert_true(q3.is_close(16.15))
  assert_true(summary.iqr.is_close(13.125))
  assert_true(summary.batch_size == 3)
  assert_true(summary.runs == 8)
}
