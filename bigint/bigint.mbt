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

///|
pub impl ToJson for BigInt with to_json(self : BigInt) -> Json {
  Json::string(self.to_string())
}

///|
pub impl @json.FromJson for BigInt with from_json(json, path) {
  guard json is String(s) else {
    raise @json.JsonDecodeError((path, "BigInt::from_json: expected number"))
  }
  BigInt::from_string(s)
}

///|
pub impl @quickcheck.Arbitrary for BigInt with arbitrary(size, rs) {
  if size == 0 {
    0
  } else {
    rs.next_int64() |> BigInt::from_int64
  }
}
