// Copyright 2024 International Digital Economy Academy
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

/// A simple implementation of the State Monad.
struct State[S, V] {
  runState : (S) -> (V, S)
}

/// Create a new state monad with a value.
/// 
/// # Example
/// ```
/// let state: State[List[Int], Int] = State::new(10)
/// ```
pub fn State::new[S, V](val : V) -> State[S, V] {
  { runState: fn { state => (val, state) } }
}

test "new" {
  let state : State[Int, Int] = State::new(10)
  @assertion.assert_eq(run_state(state, 0), (10, 0))?
}

/// Embed a simple state action into the state monad.
/// 
/// # Example
/// ```
/// let state: State[Int, Int] = state(fn { x => (x + 1, x + 1) })
/// ```
pub fn state[S, V](f : (S) -> (V, S)) -> State[S, V] {
  { runState: f }
}

test "state" {
  let state : State[Int, Int] = state(fn { x => (x + 1, x + 1) })
  @assertion.assert_eq(run_state(state, 0), (1, 1))?
}

/// Return the state from the internals of the monad.
/// 
/// # Example
/// ```
/// let state: State[Int, Int] = State::new(10)
///   |> bind(fn { _ => get() })
/// ```
pub fn get[S]() -> State[S, S] {
  { runState: fn { state => (state, state) } }
}

test "get" {
  let state : State[Int, Int] = State::new(10) |> bind(fn { _ => get() })
  @assertion.assert_eq(run_state(state, 20), (20, 20))?
}

/// Replace the state inside the monad.
/// 
/// # Example
/// ```
/// let state: State[Int, Unit] = State::new(10)
///  |> bind(fn { _ => put(20) })
/// ```
pub fn put[S](new_state : S) -> State[S, Unit] {
  { runState: fn { _ => ((), new_state) } }
}

test "put" {
  let state : State[Int, Unit] = State::new(10) |> bind(fn { _ => put(20) })
  @assertion.assert_eq(run_state(state, 0), ((), 20))?
}

/// Maps a value inside a state monad.
/// 
/// # Example
/// ```
/// let state : State[Int, Int] = State::new(10)
///   |> map(fn { x => x + 1 })
/// ```
pub fn map[S, V, W](self : State[S, V], f : (V) -> W) -> State[S, W] {
  {
    runState: fn(state : S) {
      let (val, new_state) = (self.runState)(state)
      (f(val), new_state)
    },
  }
}

test "map" {
  let state : State[Int, Int] = State::new(10) |> map(fn { x => x + 1 })
  @assertion.assert_eq(run_state(state, 0), (11, 0))?
}

/// Maps an old state to a new state inside a state monad.
/// 
/// # Example
/// ```
/// let state : State[Int, Int] = State::new(0)
///  |> bind(fn { _ => modify(fn { x => x + 1 }) })
///  |> bind(fn {_  => get()})
/// ```
pub fn modify[S](f : (S) -> S) -> State[S, Unit] {
  { runState: fn(state : S) { ((), f(state)) } }
}

test "modify" {
  let state : State[Int, Int] = State::new(0)
    |> bind(fn { _ => modify(fn { x => x + 1 }) })
    |> bind(fn { _ => get() })
  @assertion.assert_eq(run_state(state, 0), (1, 1))?
}

/// Bind a state monad computation to a function.
/// 
/// # Example
/// ```
/// let state : State[Int, Int] = State::new(10)
///  |> bind(fn { _ => put(20) })
///  |> bind(fn { _ => get() |> bind(fn { x => new(x + 1) }) })
/// ```
pub fn bind[S, V, W](self : State[S, V], f : (V) -> State[S, W]) -> State[S, W] {
  {
    runState: fn(state : S) {
      let (val, new_state) = (self.runState)(state)
      let { runState: g } = f(val)
      g(new_state)
    },
  }
}

test "bind" {
  let state : State[Int, Int] = State::new(10)
    |> bind(fn { _ => put(20) })
    |> bind(fn { _ => get() |> bind(fn { x => new(x + 1) }) })
  @assertion.assert_eq(run_state(state, 0), (21, 20))?
}

/// Unwrap a state monad computation as a function.
/// 
/// # Example
/// ```
/// let state : State[Int, Int] = State::new(10)
/// run_state(state, 0)
/// ```
pub fn run_state[S, V](self : State[S, V], state : S) -> (V, S) {
  (self.runState)(state)
}

test "run_state" {
  let state : State[Int, Int] = State::new(10)
  @assertion.assert_eq(run_state(state, 0), (10, 0))?
}

/// Evaluate a state computation with the given initial state and return the final value, discarding the final state.
/// 
/// # Example
pub fn eval_state[S, V](self : State[S, V], state : S) -> V {
  run_state(self, state).0
}

test "eval_state" {
  let state : State[Int, Int] = State::new(10)
    |> bind(fn { _ => put(20) })
    |> bind(fn { _ => get() |> bind(fn { x => new(x + 1) }) })
  @assertion.assert_eq(eval_state(state, 0), 21)?
}

/// Evaluate a state computation with the given initial state and return the final state, discarding the final value.
/// 
/// # Example
/// ```
/// let state : State[Int, Unit] = State::new(10)
///  |> bind(fn { _ => put(20) })
/// ```
pub fn exec_state[S, V](self : State[S, V], state : S) -> S {
  run_state(self, state).1
}

test "exec_state" {
  let state : State[Int, Unit] = State::new(10) |> bind(fn { _ => put(20) })
  @assertion.assert_eq(exec_state(state, 0), 20)?
}

test "state_stack" {
  fn push(n : Int) -> State[List[Int], Int] {
    { runState: fn(ns : List[Int]) { (n, Cons(n, ns)) } }
  }

  fn pop() -> State[List[Int], Int] {
    {
      runState: fn(ns : List[Int]) {
        match ns {
          Cons(n, ns) => (n, ns)
          Nil => abort("empty stack")
        }
      },
    }
  }

  fn plus() -> State[List[Int], Int] {
    bind(pop(), fn(n1) { bind(pop(), fn(n2) { push(n1 + n2) }) })
  }

  fn mult() -> State[List[Int], Int] {
    bind(pop(), fn(n1) { bind(pop(), fn(n2) { push(n1 * n2) }) })
  }

  let prog : State[List[Int], Int] = push(2)
    |> bind(fn { _ => push(3) })
    |> bind(fn { _ => push(5) })
    |> bind(fn { _ => plus() })
    |> bind(fn { _ => mult() })
  @assertion.assert_eq(run_state(prog, Nil), (16, Cons(16, Nil)))?
  let prog2 : State[List[Int], String] = State::new(10)
    |> bind(fn { x => push(3 + x) })
    |> bind(fn { _ => push(5) })
    |> bind(fn { _ => mult() })
    |> map(fn { x => x.to_string() })
  @assertion.assert_eq(eval_state(prog2, Nil), "65")?
  let prog3 = push(2) |> bind(fn { _ => push(3) }) |> bind(fn { _ => get() })
  @assertion.assert_eq(eval_state(prog3, Nil), Cons(3, Cons(2, Nil)))?
  let prog4 = State::new(0)
    |> bind(fn { _ => put(123) })
    |> bind(fn { _ => get() })
  @assertion.assert_eq(run_state(prog4, 0), (123, 123))?
  let prog5 : State[List[Int], Int] = State::new(5)
  @assertion.assert_eq(eval_state(prog5, Nil), 5)?
  let prog6 : State[List[Int], Int] = push(2)
    |> bind(fn { _ => modify(fn { x => Cons(100, x) }) })
    |> bind(fn { _ => mult() })
  @assertion.assert_eq(run_state(prog6, Nil), (200, Cons(200, Nil)))?
}

test "tick_state" {
  fn tick() -> State[Int, Int] {
    get().bind(fn { x => put(x + 1).bind(fn { _ => new(x)}) })
  }

  for i = 0; i < 100 ; i = i + 1 {
    @assertion.assert_eq(exec_state(tick(), i), i + 1)?
  }
}

fn left_identity[S, V](
  x : V,
  f : (V) -> State[S, V]
) -> (State[S, V], State[S, V]) {
  (State::new(x).bind(f), f(x))
}

fn right_identity[S, V](m : State[S, V]) -> (State[S, V], State[S, V]) {
  (m, m.bind(State::new))
}

fn bind_associator[S, V, W, X](
  m : State[S, V],
  f : (V) -> State[S, W],
  g : (W) -> State[S, X]
) -> (State[S, X], State[S, X]) {
  (m.bind(f).bind(g), m.bind(fn { x => f(x).bind(g) }))
}

fn run_state_eq[S : Eq + Show, V : Eq + Show](
  m : (State[S, V], State[S, V]),
  state : S
) -> Bool {
  let (v1, s1) = run_state(m.0, state)
  let (v2, s2) = run_state(m.1, state)
  v1 == v2 && s1 == s2
}

test "state_monad_laws" {
  let counter = State::new(10)
  fn add(s) -> State[Int, Int] {
    put(s + 2).bind(fn { _ => get() })
  }

  fn mul(s) -> State[Int, Int] {
    put(s * 2).bind(fn { _ => get() })
  }

  let m1 = left_identity(10, add)
  @assertion.assert_true(run_state_eq(m1, 0))?
  let m2 = right_identity(counter)
  @assertion.assert_true(run_state_eq(m2, 0))?
  let m3 = bind_associator(counter, add, mul)
  @assertion.assert_true(run_state_eq(m3, 0))?
}

fn map_identity[S, V](m : State[S, V]) -> State[S, V] {
  m.map(fn { x => x })
}

fn map_associator[S, V, W, X](
  m : State[S, V],
  f : (V) -> W,
  g : (W) -> X
) -> (State[S, X], State[S, X]) {
  (m.map(f).map(g), m.map(fn { x => g(f(x)) }))
}

test "state_functor_laws" {
  let counter = State::new(10)
  let add = fn { x => x + 2 }
  let mul = fn { x => x * 2 }
  let m1 = map_identity(counter)
  @assertion.assert_true(run_state_eq((counter, m1), 0))?
  let m2 = map_associator(counter, add, mul)
  @assertion.assert_true(run_state_eq(m2, 0))?
}
