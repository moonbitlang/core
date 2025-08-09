// Test coverage for mathematical prime testing edge cases

/// Test is_probable_prime with non-positive iters parameter  
test "panic is_probable_prime_zero_iters" {
  let rand = @random.Rand::new()
  let prime = @bigint.BigInt::from_string("17")
  
  // Test with zero iterations - should panic
  @math.is_probable_prime(prime, rand, iters=0) |> ignore
}

/// Test is_probable_prime with negative iterations
test "panic is_probable_prime_negative_iters" {
  let rand = @random.Rand::new()
  let prime = @bigint.BigInt::from_string("17")
  
  // Test with negative iterations - should panic
  @math.is_probable_prime(prime, rand, iters=-5) |> ignore
}

/// Test prime testing with large bit length numbers to trigger different internal paths
test "is_probable_prime_large_bit_lengths" {
  let rand = @random.Rand::new()
  
  // Test with very large composite numbers to trigger different trial division counts
  // These are crafted to test different bit length ranges in the internal trial_divisions function
  
  // Test ~1000 bit number (should use 128 trial divisions)
  let large_composite1 = @bigint.BigInt::from_string("1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000")  // Very large composite
  let result1 = @math.is_probable_prime(large_composite1, rand, iters=5)
  inspect(result1, content="false")  // This number is definitely composite
  
  // Test moderately large known composite
  let large_composite2 = @bigint.BigInt::from_string("12345678901234567890123456789012345678901")
  let result2 = @math.is_probable_prime(large_composite2, rand, iters=5)
  inspect(result2, content="false")  // This is composite
}

/// Test prime generation with different bit lengths
test "probable_prime_different_bit_lengths" {
  let rand = @random.Rand::new()
  
  // Generate primes with different bit lengths to exercise different code paths
  let small_prime = @math.probable_prime(8, rand)  // 8-bit prime
  let is_prime = @math.is_probable_prime(small_prime, rand, iters=10)
  inspect(is_prime, content="true")
  inspect(small_prime.bit_length() <= 8, content="true")
  
  let medium_prime = @math.probable_prime(64, rand)  // 64-bit prime  
  let is_prime2 = @math.is_probable_prime(medium_prime, rand, iters=10)
  inspect(is_prime2, content="true")
  inspect(medium_prime.bit_length() <= 64, content="true")
}

/// Test edge cases of probable_prime generation
test "probable_prime_edge_cases" {
  let rand = @random.Rand::new()
  
  // Test minimum bit length
  let tiny_prime = @math.probable_prime(2, rand)  // 2-bit prime (should be 2 or 3)
  let is_small = tiny_prime == 2N || tiny_prime == 3N
  inspect(is_small, content="true")
  let is_prime = @math.is_probable_prime(tiny_prime, rand)
  inspect(is_prime, content="true")
  
  // Test slightly larger bit length
  let small_prime = @math.probable_prime(16, rand)
  let is_prime2 = @math.is_probable_prime(small_prime, rand)
  inspect(is_prime2, content="true")
  inspect(small_prime.bit_length() <= 16, content="true")
}

/// Test is_probable_prime with various edge case numbers
test "is_probable_prime_edge_case_numbers" {
  let rand = @random.Rand::new()
  
  // Test with 1 (should return false)
  inspect(@math.is_probable_prime(@bigint.BigInt::from_string("1"), rand), content="false")
  
  // Test with 2 (should return true)
  inspect(@math.is_probable_prime(@bigint.BigInt::from_string("2"), rand), content="true")
  
  // Test with 3 (should return true)
  inspect(@math.is_probable_prime(@bigint.BigInt::from_string("3"), rand), content="true")
  
  // Test with 4 (even, should return false)
  inspect(@math.is_probable_prime(@bigint.BigInt::from_string("4"), rand), content="false")
  
  // Test with 0 (should return false)
  inspect(@math.is_probable_prime(@bigint.BigInt::from_string("0"), rand), content="false")
  
  // Test with negative number (should return false)
  inspect(@math.is_probable_prime(@bigint.BigInt::from_string("-5"), rand), content="false")
}

/// Test primality testing with known large primes and composites
test "is_probable_prime_known_large_numbers" {
  let rand = @random.Rand::new()
  
  // Test with a known large prime (Mersenne prime 2^127 - 1)
  let mersenne_127 = @bigint.BigInt::from_string("170141183460469231731687303715884105727")
  inspect(@math.is_probable_prime(mersenne_127, rand, iters=10), content="true")
  
  // Test with a large composite (product of two primes)
  let large_composite = @bigint.BigInt::from_string("323")  // 17 * 19
  inspect(@math.is_probable_prime(large_composite, rand, iters=10), content="false")
}

/// Test with various iteration counts to ensure robustness
test "is_probable_prime_various_iteration_counts" {
  let rand = @random.Rand::new()
  let prime = @bigint.BigInt::from_string("97")  // Known prime
  let composite = @bigint.BigInt::from_string("99")  // 9 * 11
  
  // Test with minimum iterations
  inspect(@math.is_probable_prime(prime, rand, iters=1), content="true")
  inspect(@math.is_probable_prime(composite, rand, iters=1), content="false")
  
  // Test with moderate iterations
  inspect(@math.is_probable_prime(prime, rand, iters=10), content="true")
  inspect(@math.is_probable_prime(composite, rand, iters=10), content="false")
  
  // Test with high iterations
  inspect(@math.is_probable_prime(prime, rand, iters=100), content="true")
  inspect(@math.is_probable_prime(composite, rand, iters=100), content="false")
}