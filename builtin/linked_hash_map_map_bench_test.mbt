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
test "bench Map::map int n=0" (it : @bench.T) {
  let m : Map[Int, Int] = Map([])
  for i in 0..<0 {
    m[i * 1103515245] = i
  }
  it.bench(fn() { it.keep(m.map((_, v) => v + 1)) })
}

///|
test "bench Map::map int n=1" (it : @bench.T) {
  let m : Map[Int, Int] = Map([])
  for i in 0..<1 {
    m[i * 1103515245] = i
  }
  it.bench(fn() { it.keep(m.map((_, v) => v + 1)) })
}

///|
test "bench Map::map int n=16" (it : @bench.T) {
  let m : Map[Int, Int] = Map([])
  for i in 0..<16 {
    m[i * 1103515245] = i
  }
  it.bench(fn() { it.keep(m.map((_, v) => v + 1)) })
}

///|
test "bench Map::map int n=10000" (it : @bench.T) {
  let m : Map[Int, Int] = Map([])
  for i in 0..<10000 {
    m[i * 1103515245] = i
  }
  it.bench(fn() { it.keep(m.map((_, v) => v + 1)) })
}

///|
test "bench Map::map int n=100000" (it : @bench.T) {
  let m : Map[Int, Int] = Map([])
  for i in 0..<100000 {
    m[i * 1103515245] = i
  }
  it.bench(fn() { it.keep(m.map((_, v) => v + 1)) })
}

///|
test "bench Map::map string n=10000" (it : @bench.T) {
  let m = Map([ for i in 0..<10000 => ("key-number-\{i}-with-some-length", i) ])
  it.bench(fn() { it.keep(m.map((_, v) => v + 1)) })
}
