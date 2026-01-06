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
suberror IntError Int

///|
test "show error" {
  fn f(b : Bool) -> String raise {
    if b {
      "ok"
    } else {
      raise IntError(42)
    }
  }

  inspect(try! f(true), content="ok")
  inspect(
    try? f(false),
    content="Err(moonbitlang/core/error_blackbox_test.IntError.IntError)",
  )
}

///|
/// This could be mimicked using defer in swift
/// ```swift
/// func protect<A, E: Error>(finally: () -> Void, work: () throws -> A) rethrows -> A {
///   do {
///     return try work()
///   } catch {
///     finally()
///     throw error 
///   }
/// }
/// ```
/// The design choice is that `finally` should be allowed to throw or not
/// If it does throw, which error should be raised?
/// here `protect` raise the `work` error
fn[A, E : Error] protect(
  finalize~ : () -> Unit raise?,
  work : () -> A raise E,
) -> A raise E {
  try work() catch {
    e => {
      finalize() catch {
        _ => ()
      }
      raise e
    }
  } noraise {
    x => {
      finalize() catch {
        _ => ()
      }
      x
    }
  }
}

///|
/// here `protect2` raise the `finally` error
/// this is more intuitive
/// However, due to the error comes from multiple sources,
/// it is hard to track which error is the original one
/// in the type system
fn[A] protect2(finalize~ : () -> Unit raise?, work : () -> A raise) -> A raise {
  try work() catch {
    e => {
      finalize()
      raise e
    }
  } noraise {
    x => {
      finalize()
      x
    }
  }
}

///|
test "protect" {
  let x = try? protect(finalize=() => (), () => if true {
    raise Failure::Failure("error")
  } else {
    1
  })
  inspect(
    x,
    content=(
      #|Err(Failure("error"))
    ),
  )
}

///|
test "protect & finally raise error" {
  let x = try? protect(finalize=() => raise Failure::Failure("finally error"), () => if true {
    raise Failure::Failure("error")
  } else {
    1
  })
  inspect(
    x,
    content=(
      #|Err(Failure("error"))
    ),
  )
}

///|
test "protect2" {
  let x = try? protect2(finalize=() => (), () => if true {
    raise Failure::Failure("error")
  } else {
    1
  })
  inspect(
    x,
    content=(
      #|Err(Failure("error"))
    ),
  )
}

///|
test "protect2 & finally raise error" {
  let x = try? protect2(
    finalize=() => raise Failure::Failure("finally error"),
    () => if true { raise Failure::Failure("error") } else { 1 },
  )
  inspect(
    x,
    content=(
      #|Err(Failure("finally error"))
    ),
  )
}

///|
suberror ErrWithToJson Int derive(ToJson)

///|
suberror ErrWithoutToJson Int

///|
test "error to json" {
  //TODO: note despite `impl ToJson for Error`, for suberror
  // we can not use `@json.inspect` to inspect the error
  // @json.inspect(ErrWithoutToJson(42))
  // This also applies to `impl Show for Error`, for suberror
  // we can not use `inspect` to inspect the error
  // we may auto-derive `ToJson` and `Show` for suberror automatically
  // to enhance the user experience
  fn j(err : Error) {
    err.to_json()
  }

  inspect(
    j(ErrWithToJson(42)),
    content=(
      #|Array([String("ErrWithToJson"), Number(42)])
    ),
  )
  inspect(
    j(ErrWithoutToJson(42)),
    content=(
      #|String("moonbitlang/core/error_blackbox_test.ErrWithoutToJson.ErrWithoutToJson")
    ),
  )
}
