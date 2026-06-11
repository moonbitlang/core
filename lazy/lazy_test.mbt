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
test "Lazy defers evaluation" {
  let mut runs = 0
  let cell = @lazy.Lazy(() => {
    runs += 1
    "hello"
  })
  assert_eq(runs, 0)
  assert_eq(cell.force(), "hello")
  assert_eq(runs, 1)
}

///|
test "force memoizes the result" {
  let mut runs = 0
  let cell = @lazy.Lazy(() => {
    runs += 1
    runs * 10
  })
  assert_eq(cell.force(), 10)
  assert_eq(cell.force(), 10)
  assert_eq(cell.force(), 10)
  assert_eq(runs, 1)
}

///|
test "ready returns the value without running anything" {
  let cell = @lazy.Lazy::ready(99)
  assert_eq(cell.force(), 99)
  assert_eq(cell.force(), 99)
}

///|
test "force returns each captured value" {
  let cells = [@lazy.Lazy(() => 1), Lazy(() => 2), Lazy(() => 3)]
  let mut sum = 0
  for c in cells {
    sum += c.force()
  }
  assert_eq(sum, 6)
}

///|
test "peek does not force the thunk" {
  let mut runs = 0
  let cell = @lazy.Lazy(() => {
    runs += 1
    "x"
  })
  debug_inspect(cell.peek(), content="None")
  inspect(runs, content="0")
  ignore(cell.force())
  debug_inspect(
    cell.peek(),
    content=(
      #|Some("x")
    ),
  )
  inspect(runs, content="1")
}

///|
test "peek on a ready cell returns Some without running" {
  let cell = @lazy.Lazy::ready(42)
  debug_inspect(cell.peek(), content="Some(42)")
}

///|
test "Debug renders forced and unforced cells safely" {
  let unforced : @lazy.Lazy[Int] = Lazy(() => abort("must not run"))
  @debug.debug_inspect(unforced, content="<Lazy: ...>")
  let forced = @lazy.Lazy::ready(42)
  @debug.debug_inspect(forced, content="<Lazy: 42>")
  let later = @lazy.Lazy(() => 7)
  @debug.debug_inspect(later, content="<Lazy: ...>")
  ignore(later.force())
  @debug.debug_inspect(later, content="<Lazy: 7>")
}

///|
test "Debug renders the in-progress Forcing state" {
  // A thunk that, while running, observes its own cell sees the
  // transient `Forcing` state. `Debug` surfaces this explicitly to help
  // diagnose the reentrancy that would otherwise abort `force`.
  // The thunk signature is non-raising, so we capture the rendered
  // string and assert outside.
  let observed : Ref[String] = Ref("")
  let holder : Array[@lazy.Lazy[Int]] = []
  let cell = @lazy.Lazy(() => {
    observed.val = @debug.to_repr(holder[0]).to_string()
    42
  })
  holder.push(cell)
  inspect(cell.force(), content="42")
  inspect(observed.val, content="<Lazy: forcing>")
  @debug.debug_inspect(cell, content="<Lazy: 42>")
}

///|
test "Result-as-data bridge for fallible thunks" {
  let mut runs = 0
  let cell : @lazy.Lazy[Result[Int, Error]] = Lazy(() => {
    runs += 1
    Ok(
      {
        if runs > 1 {
          fail("should not re-run")
        }
        runs
      },
    ) catch {
      e => Err(e)
    }
  })
  assert_true(cell.force() is Ok(1))
  assert_true(cell.force() is Ok(1))
  assert_eq(runs, 1)
}
