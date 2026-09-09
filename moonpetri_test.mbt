///|
fn[T] expect_ok(r : Result[T, PetriError]) -> T {
  match r {
    Ok(x) => x
    Err(_) => panic()
  }
}

///|
test "firing consumes and produces tokens" {
  let n = PetriNet::new()
  let p = expect_ok(n.add_place("p", 1))
  let q = expect_ok(n.add_place("q", 0))
  let t = expect_ok(n.add_transition("move"))
  expect_ok(n.add_input(p, t, 1))
  expect_ok(n.add_output(t, q, 1))
  let m = expect_ok(fire(n, n.initial_marking(), t))
  assert_eq(m.tokens[p], 0)
  assert_eq(m.tokens[q], 1)
}

///|
test "bounded reachability finds deadlock" {
  let n = PetriNet::new()
  let p = expect_ok(n.add_place("p", 1))
  let t = expect_ok(n.add_transition("stop"))
  expect_ok(n.add_input(p, t, 1))
  let r = expect_ok(reachable(n, n.initial_marking(), 10))
  assert_eq(r.states.length(), 2)
  assert_eq(deadlocks(n, r).length(), 1)
}
test "invalid input is rejected" {
  let n = PetriNet::new()
  assert_true(n.add_place("", 0).is_err())
  assert_true(n.add_place("p", -1).is_err())
  assert_true(n.add_transition("").is_err())
}
