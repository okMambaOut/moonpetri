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

///|
test "invalid input is rejected" {
  let n = PetriNet::new()
  assert_true(n.add_place("", 0) is Err(_))
  assert_true(n.add_place("p", -1) is Err(_))
  assert_true(n.add_transition("") is Err(_))
}

///|
test "duplicate arcs merge" {
  let n = PetriNet::new()
  let p = expect_ok(n.add_place("p", 2))
  let t = expect_ok(n.add_transition("t"))
  expect_ok(n.add_input(p, t, 1))
  expect_ok(n.add_input(p, t, 1))
  assert_true(enabled(n, n.initial_marking(), t))
}

///|
test "disabled transition cannot fire" {
  let n = PetriNet::new()
  let p = expect_ok(n.add_place("p", 0))
  let t = expect_ok(n.add_transition("t"))
  expect_ok(n.add_input(p, t, 1))
  assert_true(fire(n, n.initial_marking(), t) is Err(_))
}

///|
test "sequence applies in order" {
  let n = PetriNet::new()
  let p = expect_ok(n.add_place("p", 1))
  let q = expect_ok(n.add_place("q", 0))
  let t = expect_ok(n.add_transition("move"))
  expect_ok(n.add_input(p, t, 1))
  expect_ok(n.add_output(t, q, 1))
  let m = expect_ok(fire_sequence(n, n.initial_marking(), [t]))
  assert_eq(m.tokens[q], 1)
}

///|
test "state cap result is deterministic" {
  let n = PetriNet::new()
  let p = expect_ok(n.add_place("p", 1))
  let t = expect_ok(n.add_transition("loop"))
  expect_ok(n.add_input(p, t, 1))
  expect_ok(n.add_output(t, p, 1))
  let r = expect_ok(reachable(n, n.initial_marking(), 1))
  assert_false(r.truncated)
}

///|
test "shortest trace starts empty" {
  let n = PetriNet::new()
  let _ = expect_ok(n.add_place("p", 0))
  let r = expect_ok(reachable(n, n.initial_marking(), 4))
  assert_eq(shortest_trace(r, n.initial_marking()).unwrap().length(), 0)
}

///|
test "analysis report summarizes exploration" {
  let n = PetriNet::new()
  let p = expect_ok(n.add_place("p", 1))
  let t = expect_ok(n.add_transition("stop"))
  expect_ok(n.add_input(p, t, 1))
  let r = expect_ok(reachable(n, n.initial_marking(), 4))
  let report = analysis_report(n, r)
  assert_eq(report.states, 2)
  assert_eq(report.deadlocks, 1)
}

///|
test "marking fingerprint is stable" {
  assert_eq(marking_fingerprint(marking([1, 0, 2])), "1,0,2")
}
