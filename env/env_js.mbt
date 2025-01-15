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
extern "js" fn get_cli_args_internal() -> Array[String] =
  #| function() {
  #|  if (typeof process !== "undefined" && typeof process.argv !== "undefined") {
  #|    return process.argv;
  #|  } else {
  #|    return [];
  #|  }
  #| }

///|
extern "js" fn now_internal() -> UInt64 =
  #| function() {
  #|   const nowMs = Date.now();
  #|   return ({ hi : Number(BigInt(nowMs) >> 32n), lo : nowMs & 0xFFFFFFFF });
  #| }
