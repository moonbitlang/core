/// Trait for types whose elements can test for equality
pub trait Eq {
  op_equal(Self, Self) -> Bool
}

/// Trait for types whose elements are ordered
///
/// The return value of [compare] is:
/// - zero, if the two arguments are equal
/// - negative, if the first argument is smaller
/// - positive, if the second argument is greater
pub trait Compare: Eq {
  compare(Self, Self) -> Int
}

/// Trait for types that can be hashed
pub trait Hash {
  hash(Self) -> Int
}

/// Trait for types with a default value
pub trait Default {
  default() -> Self
}

/// Trait for types that can be converted to `String`
pub trait Show {
  to_string(Self) -> String
}
