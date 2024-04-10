enum Control[R] {
  Continue(R)
  Break(R)
}

// Reducer is essentially the body of the loop
type Reducer[Acc, Item] (Acc, Item) -> Control[Acc]

type Transducer[Acc, Item1, Item2] (Reducer[Acc, Item2]) -> Reducer[Acc, Item1]

// Folder is an abstract container with a shape of loop, and the loop body
// can be transformed by transducers
type Folder[Acc, Item] (Reducer[Acc, Item], Acc) -> Control[Acc]

fn Folder::from_array[Acc, Item](xs: Array[Item]) -> Folder[Acc, Item] {
  fn aux(step: Reducer[Acc, Item], init: Acc) -> Control[Acc] {
    let len = xs.length()
    for i = 0, acc1 = init; i < len; {
      match step.0(acc1, xs[i]) {
        Continue(acc2) => continue i+1, acc2
        Break(acc2) => break Break(acc2)
      }
    } else {
      Continue(acc1)
    }
  }
  Folder::Folder(aux)
}

// generate [n, n, n, ...] infinite sequence
fn Folder::cycle[Acc](n: Int) -> Folder[Acc, Int] {
  fn aux(step: Reducer[Acc, Int], init: Acc) -> Control[Acc] {
    for acc1 = init {
      match step.0(acc1, n) {
        Continue(acc2) => continue acc2
        Break(acc2) => break Break(acc2)
      }
    }
  }
  Folder::Folder(aux)
}

fn reduce[Acc, Item](self: Folder[Acc, Item], reduce: (Acc, Item) -> Control[Acc], init: Acc) -> Control[Acc] {
  self.0(Reducer::Reducer(reduce), init) 
}

fn transduce[Acc, Item1, Item2](self: Folder[Acc, Item1], transducer: Transducer[Acc, Item1, Item2]) -> Folder[Acc, Item2] {
  fn aux(step: Reducer[Acc, Item2], init: Acc) -> Control[Acc] {
    (self.reduce(fn (acc, item1) { transducer.0(step).0(acc, item1) }, init))
  }
  Folder::Folder(aux)
}

fn map_transducer[Acc, Item1, Item2](f: (Item1) -> Item2) -> Transducer[Acc, Item1, Item2] {
  Transducer::Transducer(fn (reducer) { 
    Reducer::Reducer( fn (acc, item1) { reducer.0(acc, f(item1)) }  )})
}

fn filter_tranducer[Acc, Item](f: (Item) -> Bool) -> Transducer[Acc, Item, Item] {
  Transducer::Transducer(fn (reducer) { 
    Reducer::Reducer( fn (acc, item) { if f(item) { reducer.0(acc, item) } else { Continue(acc) } })})
}

fn take_tranducer[Acc, Item](n: Int) -> Transducer[Acc, Item, Item] {
  let mut count = 0
  Transducer::Transducer(fn (reducer) { 
    Reducer::Reducer( fn (acc, item) { 
      count += 1
      if count <= n { reducer.0(acc, item) } else { Break(acc) }
    })})
}

fn flat_map_tranducer[Acc, Item1, Item2](f: (Item1) -> Folder[Acc, Item2]) -> Transducer[Acc, Item1, Item2] {
  Transducer::Transducer(fn (reducer) { 
    Reducer::Reducer( fn (acc, item1) {
      match f(item1).reduce(reducer.0, acc) {
        Continue(acc) => Continue(acc)
        Break(acc) => Continue(acc)
      }
    })})
}

fn map[Acc, Item1, Item2](self: Folder[Acc, Item1], f: (Item1) -> Item2) -> Folder[Acc, Item2] {
  self.transduce(map_transducer(f))
}

fn filter[Acc, Item](self: Folder[Acc, Item], f: (Item) -> Bool) -> Folder[Acc, Item] {
  self.transduce(filter_tranducer(f))
}

fn take[Acc, Item](self: Folder[Acc, Item], n: Int) -> Folder[Acc, Item] {
  self.transduce(take_tranducer(n))
}

fn flat_map[Acc, Item1, Item2](self: Folder[Acc, Item1], f: (Item1) -> Folder[Acc, Item2]) -> Folder[Acc, Item2] {
  self.transduce(flat_map_tranducer(f))
}

fn collect[Item](self: Folder[@vec.Vec[Item], Item]) -> @vec.Vec[Item] {
  fn aux(acc: @vec.Vec[Item], item: Item) -> Control[@vec.Vec[Item]] {
    acc.push(item)
    Continue(acc)
  }
  match self.reduce(aux, @vec.Vec::new()) {
    Continue(acc) => acc
    Break(acc) => acc
  }
}

test "folder" {
  let res = 
  Folder::[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    .map(fn (x) { x + 1 })
    .map(fn (x) { x * x })
    .filter(fn (x) { x % 2 == 0 })
    .take(3)
    .collect()
  inspect(res, ~content="Vec::[4, 16, 36]")?
}

test "cycle" {
  let res = 
  Folder::cycle(1)
    .take(3)
    .collect()
  inspect(res, ~content="Vec::[1, 1, 1]")?
}

test "flat_map" {
  let res = 
  Folder::[1, 2, 3]
    .flat_map(fn (x) { cycle(x).take(2) })
    .collect()
  inspect(res, ~content="Vec::[1, 1, 2, 2, 3, 3]")?
}