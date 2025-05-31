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
type! IntError Int

///|
test "show error" {
  fn f(b : Bool) -> String! {
    if b {
      "ok"
    } else {
      raise IntError(42)
    }
  }

  inspect(
    try? f(true),
    content=
      #|Ok("ok")
    ,
  )
  inspect(
    try? f(false),
    content="Err(moonbitlang/core/error_blackbox_test.IntError.IntError)",
  )
}

///|
/// This could be mimiced using defer in swift
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
fn[A, E : Error] protect(finally~ : () -> Unit?Error, work : () -> A!E) -> A!E {
  try work() catch {
    e => {
      try finally() catch {
        _ => ()
      }
      raise e
    }
  } else {
    x => {
      try finally() catch {
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
fn[A] protect2(finally~ : () -> Unit?Error, work : () -> A!) -> A! {
  try work() catch {
    e => {
      finally()
      raise e
    }
  } else {
    x => {
      finally()
      x
    }
  }
}

///|
test "protect" {
  let x = try? protect(finally=fn() { println("finally") }, fn() {
      if true {
        raise Failure("error")
      } else {
        1
      }
    })
  inspect(
    x,
    content=
      #|Err("Failure(error)")
    ,
  )
}

///|
test "protect & finally raise error" {
  let x = try? protect(finally=fn() { raise Failure("finally error") }, fn() {
      if true {
        raise Failure("error")
      } else {
        1
      }
    })
  inspect(
    x,
    content=
      #|Err("Failure(error)")
    ,
  )
}

///|
test "protect2" {
  let x = try? protect2(finally=fn() { println("finally") }, fn() {
      if true {
        raise Failure("error")
      } else {
        1
      }
    })
  inspect(
    x,
    content=
      #|Err("Failure(error)")
    ,
  )
}

///|
test "protect2 & finally raise error" {
  let x = try? protect2(finally=fn() { raise Failure("finally error") }, fn() {
      if true {
        raise Failure("error")
      } else {
        1
      }
    })
  inspect(
    x,
    content=
      #|Err("Failure(finally error)")
    ,
  )
}
