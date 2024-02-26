
/// create a reference from value
pub fn ref[T](x : T) -> Ref[T] {
  { val: x }
}


/// Maps the value of a `Ref` using a given function.
///
/// # Example
///
/// ```
/// debug(ref(1).map(fn(a){ a + 1 })) //output: ref(2)
/// ```
pub fn map[T,R](self : Ref[T], f : (T) -> R) -> Ref[R] {
  { val: f(self.val) }
}

test "map" {
  let x = ref(1)
  let y = map(x, fn(a){ a + 1 })
  @assertion.assert_eq(y.val, 2)
}


/// This function allows you to temporarily replace the value of a reference with a new value, 
/// execute a given function, and then restore the original value of the reference.
///
/// # Arguments
///
/// - `self`: The reference whose value will be temporarily replaced.
/// - `a`: The new value to assign to the reference.
/// - `f`: The function to execute while the reference value is replaced.
///
/// # Returns
///
/// The result of executing the provided function `f`.
/// 
/// # Example
/// 
/// ```
/// let x = ref(1)
/// x.protext(2, fn(){
///  debug(x) //output: ref(2)
///  x.val = 3
///  debug(x) //output: ref(3)  
/// })
/// debug(x) //output: ref(1)
/// ```
pub fn protect[T,R](self : Ref[T], a : T, f : () -> R) -> R {
  let old = self.val
  self.val = a
  let r = f()
  self.val = old
  r
}

test "protect" {
  let x = ref(1)
  @assertion.assert_eq(x.val, 1)
  protect(x, 2, fn(){
     @assertion.assert_eq(x.val, 2)
  })
  @assertion.assert_eq(x.val, 1)
}

/// Swaps the values of two references.
///
/// # Example
///
/// ```
/// let x = ref(1)
/// let y = ref(2)
/// swap(x, y)
/// debug(x) //output: ref(2)
/// debug(y) //output: ref(1)
/// ```
pub fn swap[T](self : Ref[T], that : Ref[T]) {
  let tmp = self.val
  self.val = that.val
  that.val = tmp
}

test "swap" {
  let x = ref(1)
  let y = ref(2)
  swap(x, y)
  @assertion.assert_eq(x.val, 2)
  @assertion.assert_eq(y.val, 1)
}

pub fn update[T](self : Ref[T], f : (T) -> T) {
  self.val = f(self.val)
}