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
struct MyBigInt(BigInt)

///|
impl Show for MyBigInt with output(self, logger) {
  logger.write_string(
    "{limbs : \{self.limbs}, sign : \{self.sign}, len : \{self.len} }",
  )
}

///|
impl Show for Sign with output(self, logger) {
  match self {
    Positive => logger.write_string("Positive")
    Negative => logger.write_string("Negative")
  }
}

///|
test "debug_string" {
  let buf = StringBuilder::new()
  let v : Array[MyBigInt] = [0, 1, 2, 3, 4, -0, -1, -2, -3]
  (buf as &Logger).write_iter(v.iter(), sep="\n", prefix="", suffix="")
  // Logger::writer_iter()
  // trait logger has no method write_iter
  // precise:
  // (dyn Logger)::write_iter(buf,..)
  //  Logger::trait_method()
  inspect(
    buf,
    content=(
      #|{limbs : [0, 0], sign : Positive, len : 1 }
      #|{limbs : [1, 0], sign : Positive, len : 1 }
      #|{limbs : [2, 0], sign : Positive, len : 1 }
      #|{limbs : [3, 0], sign : Positive, len : 1 }
      #|{limbs : [4, 0], sign : Positive, len : 1 }
      #|{limbs : [0, 0], sign : Positive, len : 1 }
      #|{limbs : [1, 0], sign : Negative, len : 1 }
      #|{limbs : [2, 0], sign : Negative, len : 1 }
      #|{limbs : [3, 0], sign : Negative, len : 1 }
    ),
  )
}

///|
fn check_invariant(a : BigInt) -> Unit raise {
  guard a.len > 0 else { fail("invariant len > 0 is broken: len = \{a.len}") }
  for i in 0..<a.len {
    guard a.limbs[i].to_uint64() < radix else {
      fail(
        "invariant forall 0 <= i < len. 0 <= limbs[i] < radix is broken: a.limbs[\{i}] = \{a.limbs[i]}",
      )
    }
  }
  if a.limbs.iter().take(a.len).any(x => x > 0) {
    guard a.limbs[a.len - 1] > 0 else {
      fail(
        "invariant (exists 0 <= i < len. limbs[i] > 0) => limbs[len-1] > 0 is broken",
      )
    }
  } else {
    guard a.len == 1 && a.limbs[0] == 0 else {
      fail(
        "invariant (forall 0 <= i < len. limbs[i] == 0) => limbs[0] == 0 and len == 1 is broken: len = \{a.len}, limbs = \{a.limbs}",
      )
    }
  }
  guard a.limbs.iter().drop(a.len).all(x => x == 0) else {
    fail(
      "invariant forall len <= i < limbs.length(). limbs[i] == 0 is broken: len = \{a.len}, limbs = \{a.limbs}",
    )
  }
}

///|
test "shr" {
  let a = BigInt::from_int64(1234567890123456789L)
  let b = a >> 1
  check_invariant(b)
  inspect(b, content="617283945061728394")
  let c = a >> 64
  check_invariant(c)
  inspect(c, content="0")
  let a = BigInt::from_int64((radix * radix / 2).reinterpret_as_int64())
  let b = a >> (radix_bit_len * 2)
  check_invariant(b)
  inspect(b, content="0")
}

///|
test "add coverage for max(self_len, other_len)" {
  let a = BigInt::from_int(123456789)
  let b = BigInt::from_int(987654321)
  let result = a + b
  inspect(a.len, content="1")
  inspect(b.len, content="1")
  inspect(result.len, content="1")
}

///|
test "sub coverage for max(self_len, other_len)" {
  let a = BigInt::from_int(987654321)
  let b = BigInt::from_int(123456789)
  let result = a - b
  inspect(a.len, content="1")
  inspect(b.len, content="1")
  inspect(result.len, content="1")
}

///|
test "BigInt::bit_length" {
  inspect(0N.bit_length(), content="0")
  inspect(1N.bit_length(), content="1")
  inspect((-1N).bit_length(), content="0")
  inspect(16N.bit_length(), content="5")
  inspect((-16N).bit_length(), content="4")
  inspect(42N.bit_length(), content="6")
  inspect((-42N).bit_length(), content="6")
  inspect(1024N.bit_length(), content="11")
  inspect(10000000N.bit_length(), content="24")
  inspect((1N << 31).bit_length(), content="32")
  inspect((1N << 63).bit_length(), content="64")
}

///|
test "BigInt::ctz" {
  inspect(0N.ctz(), content="0")
  inspect(1N.ctz(), content="0")
  inspect(8N.ctz(), content="3") // 1000
  inspect(12N.ctz(), content="2") // 1100
  inspect(174056N.ctz(), content="3") // 101010011111101000
  inspect((1N << 31).ctz(), content="31")
  inspect((1N << 63).ctz(), content="63")
}

///|
test {
  inspect(
    MyBigInt(-9223372036854775809N),
    content="{limbs : [1, 2147483648, 0], sign : Negative, len : 2 }",
  ) // Int64.min_value - 1
  inspect(
    MyBigInt(-9223372036854775810N),
    content="{limbs : [2, 2147483648, 0], sign : Negative, len : 2 }",
  ) // Int64.min_value - 2
}
