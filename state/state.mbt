struct State[S, V] {
  runState : (S) -> (V, S)
}

pub fn State::new[S, V](val : V) -> State[S, V] {
  { runState: fn { state => (val, state) } }
}

pub fn get[S]() -> State[S, S] {
  { runState: fn { state => (state, state) } }
}

pub fn put[S](new_state : S) -> State[S, Unit] {
  { runState: fn { _ => ((), new_state) } }
}

pub fn map[S, V, W](self : State[S, V], f : (V) -> W) -> State[S, W] {
  {
    runState: fn(state : S) {
      let (val, new_state) = (self.runState)(state)
      (f(val), new_state)
    },
  }
}

pub fn modify[S](f : (S) -> S) -> State[S, Unit] {
  { runState: fn(state : S) { ((), f(state)) } }
}

pub fn bind[S, V, W](self : State[S, V], f : (V) -> State[S, W]) -> State[S, W] {
  {
    runState: fn(state : S) {
      let (val, new_state) = (self.runState)(state)
      let { runState: g } = f(val)
      g(new_state)
    },
  }
}

pub fn run_state[S, V](self : State[S, V], state : S) -> (V, S) {
  (self.runState)(state)
}

pub fn eval_state[S, V](self : State[S, V], state : S) -> V {
  run_state(self, state).0
}

pub fn exec_state[S, V](self : State[S, V], state : S) -> S {
  run_state(self, state).1
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

test "monad laws" {
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

test "functor laws" {
  let counter = State::new(10)
  let add = fn { x => x + 2 }
  let mul = fn { x => x * 2 }
  let m1 = map_identity(counter)
  @assertion.assert_true(run_state_eq((counter, m1), 0))?
  let m2 = map_associator(counter, add, mul)
  @assertion.assert_true(run_state_eq(m2, 0))?
}
