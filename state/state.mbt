struct State[S, V] {
  runState : (S) -> (V, S)
}

pub fn State::new[S, V](val : V) -> State[S, V] {
  { runState: fn(state : S) { (val, state) } }
}

pub fn get[S]() -> State[S, S] {
  { runState: fn(state : S) { (state, state) } }
}

pub fn put[S](new_state : S) -> State[S, Unit] {
  { runState: fn(_state : S) { ((), new_state) } }
}

pub fn map[S, V, W](self : State[S, V], f : (V) -> W) -> State[S, W] {
  {
    runState: fn(state : S) {
      let (val, new_state) = (self.runState)(state)
      (f(val), new_state)
    },
  }
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
  let (val, _) = run_state(self, state)
  val
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

  let prog : State[List[Int], Int] = push(2).bind(fn { _ => push(3) }).bind(
    fn { _ => push(5) },
  ).bind(fn { _ => plus() }).bind(fn { _ => mult() })
  println(run_state(prog, Nil))
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

fn associvity[S, V, W, X](
  m : State[S, V],
  f : (V) -> State[S, W],
  g : (W) -> State[S, X]
) -> (State[S, X], State[S, X]) {
  (m.bind(f).bind(g), m.bind(fn { x => f(x).bind(g) }))
}

fn run_state_eq[S : Eq, V : Eq](
  m1 : State[S, V],
  m2 : State[S, V],
  state : S
) -> Bool {
  let (v1, s1) = run_state(m1, state)
  let (v2, s2) = run_state(m2, state)
  v1 == v2 && s1 == s2
}