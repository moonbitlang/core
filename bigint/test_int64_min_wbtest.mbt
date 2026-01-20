test "verify int64_min conversion" {
  let int64_min = -9223372036854775808L
  let big = BigInt::from_int64(int64_min)
  inspect(big, content="-9223372036854775808")
  // The expected value should have limbs = [0, 2147483648, 0] and sign = Negative
  // representing 2^63
}
