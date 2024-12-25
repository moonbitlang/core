test "unsafe_pop_front after many push_front" {
  let dq = new()
  for i = 0; i < 10; i = i + 1 {
    dq.push_front(i)
  }
  for i = 0; i < 10; i = i + 1 {
    dq.unsafe_pop_front()
  }
  assert_eq!(dq.head, dq.tail)
}
