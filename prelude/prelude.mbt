///|
pub typealias ArgsLoc = @builtin.ArgsLoc

///|
pub typealias Array[X] = @builtin.Array[X]

///|
pub typealias ArrayView[X] = @builtin.ArrayView[X]

///|
pub typealias UninitializedArray[X] = @builtin.UninitializedArray[X]

///|
pub typealias BigInt = @builtin.BigInt

///|
pub typealias Failure = @builtin.Failure

///|
pub typealias Hasher = @builtin.Hasher

///|
pub typealias Iter[X] = @builtin.Iter[X]

///|
pub typealias Iter2[X, Y] = @builtin.Iter2[X, Y]

///|
pub typealias IterResult = @builtin.IterResult

///|
pub typealias Json = @builtin.Json

///|
pub typealias Map[K, V] = @builtin.Map[K, V]

///|
pub typealias Set[X] = @builtin.Set[X]

///|
pub typealias InspectError = @builtin.InspectError

///|
pub typealias SnapshotError = @builtin.SnapshotError

///|
pub typealias SourceLoc = @builtin.SourceLoc

///|
pub typealias StringBuilder = @builtin.StringBuilder

///|
pub traitalias Eq = @builtin.Eq

///|
pub traitalias Compare = @builtin.Compare

///|
pub traitalias Hash = @builtin.Hash

///|
pub traitalias Logger = @builtin.Logger

///|
pub traitalias Show = @builtin.Show

///|
pub traitalias ToJson = @builtin.ToJson

///|
pub traitalias Default = @builtin.Default

///|
/// Aborts the program with an error message. Always causes a panic, regardless
/// of the message provided.
///
/// Parameters:
///
/// * `message` : A string containing the error message to be displayed when
/// aborting.
///
/// Returns a value of type `T`. However, this function never actually returns a
/// value as it always causes a panic.
///
/// Example:
///
/// ```moonbit
/// test "panic abort/with_message" {
///   let x : Int = abort("Something went wrong") // specify return type as Int
///   ignore(x)
/// }
/// ```
pub fn abort[T](msg : String) -> T {
  @builtin.abort(msg)
}

///|
/// Asserts that two values are equal. If they are not equal, raises a failure
/// with a message containing the source location and the values being compared.
///
/// Parameters:
///
/// * `a` : First value to compare.
/// * `b` : Second value to compare.
/// * `loc` : Source location information to include in failure messages. This is
/// usually automatically provided by the compiler.
///
/// Throws a `Failure` error if the values are not equal, with a message showing
/// the location of the failing assertion and the actual values that were
/// compared.
///
/// Example:
///
/// ```moonbit
/// test "assert_eq" {
///   assert_eq!(1, 1)
///   assert_eq!("hello", "hello")
/// }
///
/// test "panic assert_eq/not_equal" {
///   ignore(assert_eq!(1, 2)) // Will fail with message showing values and location
/// }
/// ```
pub fn assert_eq[T : Eq + Show](a : T, b : T, loc~ : SourceLoc = _) -> Unit! {
  @builtin.assert_eq!(a, b, loc~)
}

///|
/// Asserts that two values of the same type are not equal. If the values are
/// equal, raises a failure with a detailed error message including the source
/// location and string representation of both values.
///
/// Parameters:
///
/// * `first` : The first value to compare.
/// * `second` : The second value to compare.
/// * `location` : Source location information for error reporting. Defaults to
/// the current location.
///
/// Throws a `Failure` error if the values are equal. The error message includes
/// the source location and string representations of both values.
///
/// Example:
///
/// ```moonbit
/// test "assert_not_eq" {
///   assert_not_eq!(1, 2) // Passes
/// }
///
/// test "panic assert_not_eq/equal_values" {
///   ignore(assert_not_eq!(42, 42)) // Fails with detailed error message
/// }
/// ```
pub fn assert_not_eq[T : Eq + Show](
  a : T,
  b : T,
  loc~ : SourceLoc = _
) -> Unit! {
  @builtin.assert_not_eq!(a, b, loc~)
}

///|
/// Asserts that the given boolean value is true. Throws an error with source
/// location information if the assertion fails.
///
/// Parameters:
///
/// * `condition` : The boolean value to be checked.
/// * `location` : The source location where the assertion is made. Defaults to
/// the current location.
///
/// Throws a `Failure` error with a descriptive message including the source
/// location if the condition is false.
///
/// Example:
///
/// ```moonbit
/// test "assert_true" {
///   assert_true!(true)
/// }
///
/// test "panic assert_true/false_condition" {
///   ignore(assert_true!(false)) // Throws Failure
/// }
/// ```
pub fn assert_true(x : Bool, loc~ : SourceLoc = _) -> Unit! {
  @builtin.assert_true!(x, loc~)
}

///|
/// Tests whether a boolean condition is false, throwing an error if the
/// condition is true.
///
/// Parameters:
///
/// * `condition` : The boolean condition to test.
/// * `location` : The source location where the assertion is made. Used in error
/// messages.
///
/// Throws a `Failure` error if the condition is true. The error message includes
/// the source location and the value that was expected to be false.
///
/// Example:
///
/// ```moonbit
/// test "assert_false" {
///   assert_false!(false)
///   assert_false!(1 > 2)
/// }
///
/// test "panic assert_false/with_true" {
///   assert_false!(true) // This will fail with an error message
/// }
/// ```
pub fn assert_false(x : Bool, loc~ : SourceLoc = _) -> Unit! {
  @builtin.assert_false!(x, loc~)
}

///|
/// Raises a `Failure` error with a given message and source location.
///
/// Parameters:
///
/// * `message` : A string containing the error message to be included in the
/// failure.
/// * `location` : The source code location where the failure occurred.
/// Automatically provided by the compiler when not specified.
///
/// Returns a value of type `T` wrapped in a `Failure` error type.
///
/// Throws an error of type `Failure` with a message that includes both the
/// source location and the provided error message.
///
/// Example:
///
/// ```moonbit
/// test "panic fail" {
///   fail!("Something went wrong")
/// }
/// ```
pub fn fail[T](msg : String, loc~ : SourceLoc = _) -> T!Failure {
  @builtin.fail!(msg, loc~)
}

///|
/// Evaluates an expression and discards its result. This is useful when you want
/// to execute an expression for its side effects but don't care about its return
/// value, or when you want to explicitly indicate that a value is intentionally
/// unused.
///
/// Parameters:
///
/// * `value` : The value to be ignored. Can be of any type.
///
/// Example:
///
/// ```moonbit
/// test "ignore" {
///   let x = 42
///   ignore(x) // Explicitly ignore the value
///   let mut sum = 0
///   ignore([1, 2, 3].iter().each(fn(x) { sum = sum + x })) // Ignore the Unit return value of each()
/// }
/// ```
pub fn ignore[T](t : T) -> Unit = "%ignore"

///|
/// Tests if the string representation of an object matches the expected content.
/// Used primarily in test cases to verify the correctness of `Show`
/// implementations and program outputs.
///
/// Parameters:
///
/// * `object` : The object to be inspected. Must implement the `Show` trait.
/// * `content` : The expected string representation of the object. Defaults to
/// an empty string.
/// * `location` : Source code location information for error reporting.
/// Automatically provided by the compiler.
/// * `arguments_location` : Location information for function arguments in
/// source code. Automatically provided by the compiler.
///
/// Throws an `InspectError` if the actual string representation of the object
/// does not match the expected content. The error message includes detailed
/// information about the mismatch, including source location and both expected
/// and actual values.
///
/// Example:
///
/// ```moonbit skip
/// test "inspect/basic" {
///   inspect!(42, content="42")
///   inspect!("hello", content="hello")
///   inspect!([1, 2, 3], content="[1, 2, 3]")
/// }
/// ```
pub fn inspect(
  obj : &Show,
  content~ : String = "",
  loc~ : SourceLoc = _,
  args_loc~ : ArgsLoc = _
) -> Unit!InspectError {
  @builtin.inspect!(obj, content~, loc~, args_loc~)
}

///|
pub fn panic[T]() -> T {
  @builtin.panic()
}

///|
/// Tests if two values are physically equal (i.e., point to the same memory
/// location). Unlike structural equality testing (`==`), this function checks if
/// two references point to exactly the same object in memory.
///
/// Parameters:
///
/// * `first` : The first value to compare.
/// * `second` : The second value to compare.
/// * `T` : The type parameter representing the type of values being compared.
///
/// Returns `true` if both values refer to the same object in memory, `false`
/// otherwise.
///
/// Example:
///
/// ```moonbit
/// test "physical_equal" {
///   let arr1 = [1, 2, 3]
///   let arr2 = arr1
///   let arr3 = [1, 2, 3]
///   inspect!(physical_equal(arr1, arr2), content="true") // Same object
///   inspect!(physical_equal(arr1, arr3), content="false") // Different objects with same content
/// }
/// ```
pub fn physical_equal[T](a : T, b : T) -> Bool {
  @builtin.physical_equal(a, b)
}

///|
/// Prints any value that implements the `Show` trait to the standard output,
/// followed by a newline.
///
/// Parameters:
///
/// * `value` : The value to be printed. Must implement the `Show` trait.
///
/// Example:
///
/// ```moonbit skip
/// test "println" {
///   println(42)
///   println("Hello, World!")
///   println([1, 2, 3])
/// }
/// ```
pub fn println[T : Show](input : T) -> Unit {
  @builtin.println(input)
}

///|
/// Performs logical negation on a boolean value.
///
/// Parameters:
///
/// * `value` : The boolean value to negate.
///
/// Returns the logical NOT of the input value: `true` if the input is `false`,
/// and `false` if the input is `true`.
///
/// Example:
///
/// ```moonbit
/// test "not" {
///   inspect!(not(true), content="false")
///   inspect!(not(false), content="true")
/// }
/// ```
pub fn not(x : Bool) -> Bool = "%bool_not"

///|
pub fn repr[T : Show](t : T) -> String {
  let logger = StringBuilder::new()
  t.output(logger)
  logger.to_string()
}

///|
/// Prints and returns the value of a given expression for quick and dirty debugging.
/// @alert deprecated "This function is for debugging only and should not be used in production"
pub fn dump[T](t : T, name? : String, loc~ : SourceLoc = _) -> T {
  let name = match name {
    Some(name) => name
    None => ""
  }
  println("dump(\{name}@\{loc}) = \{any_to_string(t)}")
  t
}

///|
fn any_to_string[T](any : T) -> String = "%any.to_string"
