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

///|
test "Double::to_uint64 across the whole input range" {
  // NaN and everything <= 0 map to 0.
  inspect((0.0 / 0.0).to_uint64(), content="0")
  inspect((-1.0 / 0.0).to_uint64(), content="0")
  inspect((-1.5).to_uint64(), content="0")
  inspect((-0.0).to_uint64(), content="0")
  inspect(0.5.to_uint64(), content="0")
  // 2^53
  inspect(9007199254740992.0.to_uint64(), content="9007199254740992")
  // largest double below 2^63 (2^63 - 1024)
  inspect(9223372036854774784.0.to_uint64(), content="9223372036854774784")
  // BUG: [2^63, 2^64) saturates on native; the correct results are
  // 9223372036854775808, 9300000000000000000, 10000000000000000000 and
  // 18446744073709549568.
  // 2^63
  inspect(9223372036854775808.0.to_uint64(), content="18446744073709551615")
  inspect(9.3e18.to_uint64(), content="18446744073709551615")
  inspect(1.0e19.to_uint64(), content="18446744073709551615")
  // largest double below 2^64 (2^64 - 2048)
  inspect(18446744073709549568.0.to_uint64(), content="18446744073709551615")
  // 2^64 and above saturate.
  inspect(18446744073709551616.0.to_uint64(), content="18446744073709551615")
  inspect((1.0 / 0.0).to_uint64(), content="18446744073709551615")
}

///|
test "Double::to_uint64 scaled unit interval" {
  // Mapping r in [0, 1) onto the full UInt64 range, as RNG / hashing /
  // fixed-point code does.
  let two64 = 18446744073709551616.0
  // BUG: on native the last two saturate; they should be
  // 9223372036854775808 and 13835058055282163712.
  inspect((0.25 * two64).to_uint64(), content="4611686018427387904")
  inspect((0.5 * two64).to_uint64(), content="18446744073709551615")
  inspect((0.75 * two64).to_uint64(), content="18446744073709551615")
}
