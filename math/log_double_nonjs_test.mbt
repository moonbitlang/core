// Copyright 2026 International Digital Economy Academy
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

// Digit-exact results of the non-JS implementations. On JS these functions
// are the engine's `Math.*`, whose last digit may legitimately differ.

///|
test "log10 rounding of inexact results" {
  // issue #4336
  inspect(@math.log10(0.75), content="-0.12493873660829995")
  inspect(@math.log10(1.625), content="0.21085336531489318")
  inspect(@math.log10(1.32421875), content="0.1219597328912326")
  inspect(@math.log10(11.0), content="1.0413926851582251")
  // The mantissa is reduced to [sqrt(2)/2, sqrt(2)) on its high word alone,
  // so the split falls at 0x3fe6a09e_00000000 and 0x3ff6a09e_00000000:
  // one input just below and one just above each.
  inspect(@math.log10(0.707106590270774), content="-0.1505151150896387")
  inspect(@math.log10(0.7071065902711), content="-0.15051511508943852")
  inspect(@math.log10(1.41421318054162), content="0.1505148805743646")
  inspect(@math.log10(1.414213562373), content="0.15051499783196143")
  // the low-order bits of log(1+f) reach the result through the lo parts
  inspect(@math.log10(0.04), content="-1.3979400086720375")
  inspect(@math.log10(1507.0), content="3.1781132523146316")
  // the rounding error of adding k*log10(2) is carried into the result
  inspect(@math.log10(0.02), content="-1.6989700043360187")
}

///|
test "log10 of powers of ten" {
  let mut p = 1.0
  for k in 0..<23 {
    // 10^k is exactly representable up to k = 22
    assert_eq(@math.log10(p), k.to_double())
    p = p * 10.0
  }
  inspect(@math.log10(1.0e-5), content="-5")
  inspect(@math.log10(1.0e100), content="100")
  inspect(@math.log10(1.0e-300), content="-300")
  inspect(@math.log10(@double.max_value), content="308.25471555991675")
}

///|
test "log10 of subnormals" {
  inspect(@math.log10(5.0e-324), content="-323.3062153431158")
  inspect(@math.log10(1.0e-310), content="-310")
  inspect(@math.log10(2.225073858507201e-308), content="-307.6526555685888")
}
