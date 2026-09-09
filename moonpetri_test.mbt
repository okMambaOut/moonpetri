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

///|
test "overflow is rejected without mutating arcs or marking" {
  let n = PetriNet::new()
  let p = expect_ok(n.add_place("p", 2147483647))
  let t = expect_ok(n.add_transition("t"))
  expect_ok(n.add_output(t, p, 1))
  assert_eq(fire(n, n.initial_marking(), t), Err(TokenOverflow))
  assert_eq(n.initial_marking().tokens[p], 2147483647)
  expect_ok(n.add_input(p, t, 2147483647))
  assert_eq(n.add_input(p, t, 1), Err(TokenOverflow))
  assert_eq(expect_ok(fire(n, n.initial_marking(), t)).tokens[p], 1)
}

///|
test "invalid marking and duplicate names are diagnosed" {
  let n = PetriNet::new()
  let _ = expect_ok(n.add_place("p", 0))
  let t = expect_ok(n.add_transition("t"))
  assert_eq(n.add_place("p", 1), Err(DuplicateName("p")))
  assert_eq(n.add_transition("t"), Err(DuplicateName("t")))
  assert_false(enabled(n, marking([-1]), t))
  assert_eq(fire(n, marking([-1]), t), Err(InvalidMarking))
  assert_eq(fire(n, marking([]), t), Err(InvalidMarking))
  assert_eq(n.add_input(-1, t, 1), Err(InvalidPlace))
  assert_eq(n.add_output(99, 0, 1), Err(InvalidTransition))
  assert_eq(n.add_input(0, t, 0), Err(InvalidWeight))
}

///|
test "sequence errors carry zero-based step and leave inputs untouched" {
  let n = PetriNet::new()
  let p = expect_ok(n.add_place("p", 1))
  let t = expect_ok(n.add_transition("consume"))
  expect_ok(n.add_input(p, t, 1))
  let start = n.initial_marking()
  assert_eq(
    fire_sequence(n, start, [t, t]),
    Err(SequenceFailed(1, t, NotEnabled)),
  )
  assert_eq(start.tokens[p], 1)
  assert_eq(fire_sequence(n, marking([-1]), []), Err(InvalidMarking))
  let copy = expect_ok(fire_sequence(n, start, []))
  copy.tokens[p] = 9
  assert_eq(start.tokens[p], 1)
}

///|
test "BFS stores shortest deterministic predecessors and enforces hard cap" {
  let n = PetriNet::new()
  let p = expect_ok(n.add_place("p", 0))
  let grow = expect_ok(n.add_transition("grow"))
  let fast = expect_ok(n.add_transition("fast"))
  expect_ok(n.add_output(grow, p, 1))
  expect_ok(n.add_output(fast, p, 2))
  let start = n.initial_marking()
  let r = expect_ok(reachable(n, start, 4))
  assert_eq(r.states.length(), 4)
  assert_true(r.truncated)
  assert_false(is_bounded(r))
  assert_eq(shortest_trace(r, marking([2])), Some([fast]))
  assert_eq(shortest_trace(r, marking([3])), Some([grow, fast]))
  assert_eq(shortest_trace(r, marking([99])), None)
  start.tokens[p] = 77
  assert_eq(r.states[0].tokens[p], 0)
  assert_true(reachable(n, n.initial_marking(), 0) is Err(InvalidMaxStates))
}
