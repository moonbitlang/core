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
/// Trait for types that can be converted to human-readable debugging info.
pub(open) trait Debug {
  #as_free_fn
  to_repr(Self) -> Repr
}

///|
pub impl Debug for Int with to_repr(self) {
  Repr::integer(self.to_string())
}

///|
pub impl Debug for Int16 with to_repr(self) {
  Repr::integer(self.to_string())
}

///|
pub impl Debug for Int64 with to_repr(self) {
  Repr::integer(self.to_string())
}

///|
pub impl Debug for UInt16 with to_repr(self) {
  Repr::integer(self.to_string())
}

///|
pub impl Debug for UInt with to_repr(self) {
  Repr::integer(self.to_string())
}

///|
pub impl Debug for UInt64 with to_repr(self) {
  Repr::integer(self.to_string())
}

///|
pub impl Debug for Double with to_repr(self) {
  Repr::double(self)
}

///|
pub impl Debug for Float with to_repr(self) {
  Repr::float(self)
}

///|
pub impl Debug for Bool with to_repr(self) {
  Repr::bool(self)
}

///|
pub impl Debug for Byte with to_repr(self) {
  // Use hex to make byte sequences easier to read.
  Repr::literal("0x" + self.to_hex())
}

///|
pub impl Debug for Char with to_repr(self) {
  Repr::char(self)
}

///|
pub impl Debug for String with to_repr(self) {
  Repr::string(self)
}

///|
pub impl Debug for StringView with to_repr(self) {
  Repr::opaque_("StringView", Repr::string(self.to_owned()))
}

///|
pub impl Debug for Bytes with to_repr(self) {
  Repr::opaque_("Bytes", Repr::array(self.to_array().map(x => to_repr(x))))
}

///|
pub impl Debug for BytesView with to_repr(self) {
  Repr::opaque_("BytesView", Repr::array(self.to_array().map(x => to_repr(x))))
}

///|
pub impl Debug for Unit with to_repr(_) {
  Repr::unit()
}

///|
pub impl[T : Debug] Debug for Array[T] with to_repr(self) {
  Repr::array(self.map(x => to_repr(x)))
}

///|
pub impl[T : Debug] Debug for ArrayView[T] with to_repr(self) {
  Repr::opaque_("ArrayView", Repr::array(self.map(x => to_repr(x))))
}

///|
pub impl[T : Debug] Debug for FixedArray[T] with to_repr(self) {
  // `FixedArray` can be viewed as `ArrayView` via slicing.
  let view : ArrayView[T] = self
  Repr::opaque_("FixedArray", Repr::array(view.map(x => to_repr(x))))
}

///|
pub impl[T : Debug] Debug for ReadOnlyArray[T] with to_repr(self) {
  // `ReadOnlyArray` can be viewed as `ArrayView` via slicing.
  let view : ArrayView[T] = self
  Repr::opaque_("ReadOnlyArray", Repr::array(view.map(x => to_repr(x))))
}

///|
pub impl[T : Debug] Debug for T? with to_repr(self) {
  match self {
    None => Repr::ctor("None", [])
    Some(x) => Repr::ctor("Some", [(None, to_repr(x))])
  }
}

///|
pub impl[T : Debug, E : Debug] Debug for Result[T, E] with to_repr(self) {
  match self {
    Ok(x) => Repr::ctor("Ok", [(None, to_repr(x))])
    Err(e) => Repr::ctor("Err", [(None, to_repr(e))])
  }
}

///|
pub impl[A] Debug for Iter[A] with to_repr(_) {
  Repr::opaque_("Iter", Omitted)
}

///|
pub impl[A, B] Debug for Iter2[A, B] with to_repr(_) {
  Repr::opaque_("Iter2", Omitted)
}

///|
pub impl[T : Debug] Debug for MutArrayView[T] with to_repr(self) {
  Repr::opaque_("MutArrayView", Repr::array(self[:].map(x => to_repr(x))))
}

///|
pub impl Debug for StringBuilder with to_repr(self) {
  Repr::string(self.to_string())
}

///|
pub impl[K : Debug, V : Debug] Debug for Map[K, V] with to_repr(self) {
  Repr::map(
    self
    .to_array()
    .map(kv => {
      let (k, v) = kv
      (to_repr(k), to_repr(v))
    }),
  )
}

///|
pub impl Debug for Json with to_repr(self) {
  match self {
    Null => Repr::ctor("Null", [])
    True => Repr::ctor("True", [])
    False => Repr::ctor("False", [])
    Number(number, repr~) =>
      match repr {
        None => Repr::ctor("Number", [(None, to_repr(number))])
        Some(_) =>
          Repr::ctor("Number", [
            (None, to_repr(number)),
            (Some("repr"), to_repr(repr)),
          ])
      }
    String(string) => Repr::ctor("String", [(None, to_repr(string))])
    Array(array) => Repr::ctor("Array", [(None, to_repr(array))])
    Object(object) => Repr::ctor("Object", [(None, to_repr(object))])
  }
}

///|
pub impl Debug for SourceLoc with to_repr(self) {
  Repr::opaque_("SourceLoc", Repr::string(self.to_string()))
}

///|
/// Checks that the structural representation (`Repr`) of an object matches the
/// expected content. Used in test blocks to ensure API results are as expected,
/// and stores a pretty-printed string for comparison.
///
/// Parameters:
/// - `obj`: The object to inspect. Must implement the `Debug` trait.
/// - `content`: The expected string representation of the object. Defaults to an empty string if not provided.
/// - `loc`: Source code location information for error reporting. Automatically provided by the compiler.
/// - `args_loc`: Location information for function arguments in the source code. Automatically provided by the compiler.
///
/// Raises an `InspectError` if the actual `Repr` does not match the expected content.
///
/// Example:
///
/// ```mbt check
/// test {
///   @debug.debug_inspect(42, content="42")
///   @debug.debug_inspect('c', content="'c'")
///   @debug.debug_inspect(
///     "hello",
///     content=(
///       #|"hello"
///     ),
///   )
///   @debug.debug_inspect(
///     ([1, 2, 3, 4], "string", Some(3.14)),
///     content=(
///       #|([1, 2, 3, 4], "string", Some(3.14))
///     ),
///   )
/// }
/// ```
#callsite(autofill(args_loc, loc))
#alias(inspect, deprecated="use `debug_inspect` without package name instead")
pub fn debug_inspect(
  obj : &Debug,
  content? : String,
  loc~ : SourceLoc,
  args_loc~ : ArgsLoc,
) -> Unit raise InspectError {
  let loc = loc.to_json_string()
  let args_loc = args_loc.to_json()
  let actual = render(obj.to_repr())
  let want = match content {
    None => ""
    Some(x) => x
  }
  if actual != want {
    raise InspectError(
      "@EXPECT_FAILED {\"loc\": \{loc}, \"args_loc\": \{args_loc}, \"expect\": \{want.escape()}, \"actual\": \{actual.escape()} }",
    )
  }
}

///|
/// Assert two values are equal for debugging/tests.
#callsite(autofill(loc))
pub fn[T : Eq + Debug] assert_eq(
  a : T,
  b : T,
  msg? : String,
  loc~ : SourceLoc,
) -> Unit raise {
  if a != b {
    let fail_msg = match msg {
      Some(msg) => msg
      None => {
        let repr_a = to_repr(a)
        let repr_b = to_repr(b)
        let diff = pretty_print_delta(diff_repr(repr_a, repr_b), use_ansi=false)
        "`\{render(repr_a)} != \{render(repr_b)}`\ndiff:\n\{diff}"
      }
    }
    fail(fail_msg, loc~)
  }
}

///|
test "core builtin Debug implementations" {
  debug_inspect((1 : Int16), content="1")
  debug_inspect((1 : UInt16), content="1")
  debug_inspect((1 : UInt64), content="1")
  debug_inspect((1.0 : Float), content="1")
  let b : Bytes = b"ab"
  debug_inspect(b, content="<Bytes: [0x61, 0x62]>")
  let bv : BytesView = b
  debug_inspect(bv, content="<BytesView: [0x61, 0x62]>")
  let sv : StringView = "abc"
  debug_inspect(
    sv,
    content=(
      #|<StringView: "abc">
    ),
  )
  let av : ArrayView[Int] = [1, 2, 3][1:3]
  debug_inspect(av, content="<ArrayView: [2, 3]>")
  let fa : FixedArray[Int] = [1, 2, 3]
  debug_inspect(fa, content="<FixedArray: [1, 2, 3]>")
  let ro : ReadOnlyArray[Int] = [1, 2, 3]
  debug_inspect(ro, content="<ReadOnlyArray: [1, 2, 3]>")
  let mv : MutArrayView[Int] = [1, 2, 3].mut_view(start=1, end=3)
  debug_inspect(mv, content="<MutArrayView: [2, 3]>")
  debug_inspect((Ok(1) : Result[Int, String]), content="Ok(1)")
  debug_inspect((Err("e") : Result[Int, String]), content="Err(\"e\")")
}

///|
/// Prints and returns the value of a given expression for quick and dirty debugging.
/// This could also be useful to print some logs to trace the progress.
/// For example, you can put `dump(())` in each line, the execution will print the line number
/// when it reaches that line.
#callsite(autofill(loc))
#deprecated("This function is for debugging only and should not be used in production", skip_current_package=true)
pub fn[T : Debug] dump(t : T, name? : String, loc~ : SourceLoc) -> T {
  let name = match name {
    Some(name) => name
    None => ""
  }
  println("dump(\{name}@\{loc}) = \{to_string(t)}")
  t
}

///|
test "dump" {
  let x = 42
  if false {
    dump(()) // never reached here
    assert_eq(dump(x) + x, 84)
  }
}

///|
pub impl Debug for InspectError with to_repr(self) {
  match self {
    InspectError(msg) => Repr::ctor("InspectError", [(None, Repr::string(msg))])
  }
}

///|
pub impl Debug for Failure with to_repr(self) {
  match self {
    Failure(msg) => Repr::ctor("Failure", [(None, Repr::string(msg))])
  }
}

///|
pub impl Debug for SnapshotError with to_repr(self) {
  match self {
    SnapshotError(msg) =>
      Repr::ctor("SnapshotError", [(None, Repr::string(msg))])
  }
}

///|
#warnings("-deprecated")
pub impl Debug for BenchError with to_repr(self) {
  match self {
    BenchError(msg) => Repr::ctor("BenchError", [(None, Repr::string(msg))])
  }
}

///|
pub impl Debug for ArgsLoc with to_repr(self) {
  let ArgsLoc(arr) = self
  Repr::opaque_("ArgsLoc", to_repr(arr))
}

///|
pub impl Debug for Hasher with to_repr(_) {
  Repr::opaque_("Hasher", Repr::omitted())
}

///|
#warnings("-deprecated")
pub impl Debug for IterResult with to_repr(self) {
  match self {
    IterEnd => Repr::ctor("IterEnd", [])
    IterContinue => Repr::ctor("IterContinue", [])
  }
}

///|
pub impl[T] Debug for UninitializedArray[T] with to_repr(_) {
  Repr::opaque_("UninitializedArray", Repr::omitted())
}

///|
test "Debug for builtin errors" {
  debug_inspect(
    InspectError::InspectError("inspect msg"),
    content="InspectError(\"inspect msg\")",
  )
  debug_inspect(
    Failure::Failure("failure msg"),
    content="Failure(\"failure msg\")",
  )
  debug_inspect(
    SnapshotError::SnapshotError("snapshot msg"),
    content="SnapshotError(\"snapshot msg\")",
  )
}
