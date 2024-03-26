test "from_array" {
  let q = Queue::[1,2,3,4]
  q.push(11)
  @assertion.assert_eq(q.pop_exn(),1)?
  @assertion.assert_eq(q.pop_exn(),2)?    
}