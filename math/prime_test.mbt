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
test "@math.is_probable_prime" {
  let r = @random.Rand::new()
  // small primes
  inspect(@math.is_probable_prime(2N, r), content="true")
  inspect(@math.is_probable_prime(3N, r), content="true")
  inspect(@math.is_probable_prime(7N, r), content="true")
  inspect(@math.is_probable_prime(17N, r), content="true")
  // https://t5k.org/lists/small
  inspect(@math.is_probable_prime(5915587277N, r), content="true")
  inspect(@math.is_probable_prime(1500450271N, r), content="true")
  inspect(@math.is_probable_prime(48112959837082048697N, r), content="true")
  inspect(@math.is_probable_prime(27542476619900900873N, r), content="true")
  inspect(
    @math.is_probable_prime(
      643808006803554439230129854961492699151386107534013432918073439524138264842370630061369715394739134090922937332590384720397133335969549256322620979036686633213903952966175107096769180017646161851573147596390153N,
      r,
    ),
    content="true",
  )
  inspect(
    @math.is_probable_prime(
      449417999055441493994709297093108513015373787049558499205492347871729927573118262811508386655998299074566974373711472560655026288668094291699357843464363003144674940345912431129144354948751003607115263071543163N,
      r,
    ),
    content="true",
  )
  inspect(
    @math.is_probable_prime(
      5521712099665906221540423207019333379125265462121169655563495403888449493493629943498064604536961775110765377745550377067893607246020694972959780839151452457728855382113555867743022746090187341871655890805971735385789993N,
      r,
    ),
    content="true",
  )

  // small composites
  inspect(@math.is_probable_prime(0N, r), content="false")
  inspect(@math.is_probable_prime(1N, r), content="false")
  inspect(@math.is_probable_prime(93N, r), content="false")
  inspect(@math.is_probable_prime(133N, r), content="false")
  // big composites
  inspect(
    @math.is_probable_prime(
      21284175091214687912771199898307297748211672914763848041968395774954376176754N,
      r,
    ),
    content="false",
  )
  inspect(
    @math.is_probable_prime(
      6084766654921918907427900243509372380954290099172559290432744450051395395951N,
      r,
    ),
    content="false",
  )
  inspect(
    @math.is_probable_prime(
      84594350493221918389213352992032324280367711247940675652888030554255915464401N,
      r,
    ),
    content="false",
  )
  // carmichael numbers
  inspect(@math.is_probable_prime(561N, r), content="false")
  inspect(@math.is_probable_prime(1729N, r), content="false")
  inspect(@math.is_probable_prime(41041N, r), content="false")
  inspect(@math.is_probable_prime(509033161N, r), content="false")
}

///|
test "@math.probable_prime" {
  let rand = @random.Rand::new()
  inspect(
    @math.is_probable_prime(@math.probable_prime(32, rand), rand),
    content="true",
  )
  inspect(
    @math.is_probable_prime(@math.probable_prime(64, rand), rand),
    content="true",
  )
  inspect(
    @math.is_probable_prime(@math.probable_prime(100, rand), rand),
    content="true",
  )
  inspect(
    @math.is_probable_prime(@math.probable_prime(256, rand), rand),
    content="true",
  )
}

///|
test "panic is_probable_prime non-positive iters" {
  let r = @random.Rand::new()
  ignore(@math.is_probable_prime(17N, r, iters=0))
}

///|
test "trial_divisions 1024-bit bucket" {
  let r = @random.Rand::new()
  let n = (1N << 1023) * 3N + 3N
  assert_false(@math.is_probable_prime(n, r))
}

///|
test "trial_divisions 2048-bit bucket" {
  let r = @random.Rand::new()
  let n = (1N << 2050) + 5N
  assert_false(@math.is_probable_prime(n, r))
}

///|
test "trial_divisions above 4096-bit bucket" {
  let r = @random.Rand::new()
  let n = (1N << 4097) + 1N
  assert_false(@math.is_probable_prime(n, r))
}

///|
#cfg(false)
test "is_probable_prime edge cases" {
  let r = @random.Rand::new()

  // Test with negative iterations (should panic)
  try {
    ignore(is_probable_prime(17N, r, iters=-1))
    assert_false(true) // Should not reach here
  } catch {
    _ => () // Expected to panic
  }

  // Test with zero iterations (should panic) 
  try {
    ignore(is_probable_prime(17N, r, iters=0))
    assert_false(true) // Should not reach here
  } catch {
    _ => () // Expected to panic
  }

  // Test with minimum positive iterations
  assert_true(is_probable_prime(17N, r, iters=1))

  // Test with 4 (even number larger than 3)
  assert_false(is_probable_prime(4N, r))

  // Test larger even numbers
  assert_false(is_probable_prime(100N, r))
  assert_false(is_probable_prime(1000N, r))
}

///|
#cfg(false)
test "trial_divisions boundary conditions" {
  let r = @random.Rand::new()

  // Test numbers that equal small primes (edge case in trial_divisions)
  assert_true(is_probable_prime(2N, r))
  assert_true(is_probable_prime(3N, r))
  assert_true(is_probable_prime(5N, r))
  assert_true(is_probable_prime(7N, r))
  assert_true(is_probable_prime(11N, r))

  // Test numbers that are multiples of small primes but not the primes themselves
  assert_false(is_probable_prime(4N, r)) // 2*2
  assert_false(is_probable_prime(6N, r)) // 2*3
  assert_false(is_probable_prime(9N, r)) // 3*3
  assert_false(is_probable_prime(15N, r)) // 3*5
  assert_false(is_probable_prime(21N, r)) // 3*7
  assert_false(is_probable_prime(25N, r)) // 5*5
}

///|
#cfg(false)
test "miller_rabin edge cases" {
  let r = @random.Rand::new()

  // Test with small numbers that would trigger edge case handling in miller_rabin_test
  // (these won't actually call miller_rabin_test due to early returns, 
  // but we test the full path)
  assert_true(is_probable_prime(5N, r))
  assert_false(is_probable_prime(8N, r))
  assert_false(is_probable_prime(10N, r))

  // Test numbers that exercise different bit length ranges for trial divisions
  // 512 bit boundary
  let mid_size = @bigint.BigInt::from_string(
    "12999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999",
  )
  ignore(is_probable_prime(mid_size, r))
}

///|
#cfg(false)
test "probable_prime different bit sizes" {
  let rand = @random.Rand::new()

  // Test various bit sizes
  for bit_size in [8, 16, 24, 48, 72, 128] {
    let prime = probable_prime(bit_size, rand)
    assert_true(is_probable_prime(prime, rand))
    // Verify the bit length is approximately correct
    assert_true(prime.bit_length() <= bit_size + 1)
    assert_true(prime.bit_length() >= bit_size - 1)
  }
}

///|
#cfg(false)
test "comprehensive primality tests" {
  let r = @random.Rand::new()

  // Test a range of small numbers to ensure comprehensive coverage
  let known_primes = [
    2N, 3N, 5N, 7N, 11N, 13N, 17N, 19N, 23N, 29N, 31N, 37N, 41N, 43N, 47N,
  ]
  let known_composites = [
    4N, 6N, 8N, 9N, 10N, 12N, 14N, 15N, 16N, 18N, 20N, 21N, 22N, 24N, 25N,
  ]
  for prime in known_primes {
    assert_true(is_probable_prime(prime, r))
  }
  for composite in known_composites {
    assert_false(is_probable_prime(composite, r))
  }
}
