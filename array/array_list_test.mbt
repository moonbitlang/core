

test "to_list" {
  let ls = [1, 2, 3, 4, 5].to_list()
  @assertion.assert_eq(ls, Cons(1, Cons(2, Cons(3, Cons(4, Cons(5, Nil))))))?
}