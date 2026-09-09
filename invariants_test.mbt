///|
test "all small weighted self-loops obey consume-then-produce semantics" {
  for initial in 0..<5 {
    for consumed in 1..<5 {
      for produced in 1..<5 {
        let n = PetriNet::new()
        ignore(n.add_place("p", initial))
        ignore(n.add_transition("t"))
        ignore(n.add_input(0, 0, consumed))
        ignore(n.add_output(0, 0, produced))
        let start = n.initial_marking()
        assert_eq(enabled(n, start, 0), initial >= consumed)
        match fire(n, start, 0) {
          Ok(next) =>
            assert_eq(next.token(0), Some(initial - consumed + produced))
          Err(e) => {
            assert_true(initial < consumed)
            assert_eq(e, NotEnabled)
          }
        }
        assert_eq(start.token(0), Some(initial))
      }
    }
  }
}

///|
test "capacity conservation BFS traces and PNML roundtrips agree across capacities" {
  for capacity in 1..<8 {
    let n = PetriNet::new()
    ignore(n.add_place("free", capacity))
    ignore(n.add_place("buffer", 0))
    ignore(n.add_transition("produce"))
    ignore(n.add_transition("consume"))
    ignore(n.add_input(0, 0, 1))
    ignore(n.add_output(0, 1, 1))
    ignore(n.add_input(1, 1, 1))
    ignore(n.add_output(1, 0, 1))
    let r = match reachable(n, n.initial_marking(), capacity + 1) {
      Ok(x) => x
      Err(_) => panic()
    }
    assert_false(r.truncated)
    assert_eq(r.state_count(), capacity + 1)
    assert_eq(r.edges, capacity * 2)
    for state in r.states() {
      assert_eq(state.tokens()[0] + state.tokens()[1], capacity)
      let path = shortest_trace(r, state).unwrap()
      assert_eq(fire_sequence(n, n.initial_marking(), path), Ok(state))
    }
    let imported = match parse_pnml(serialize_pnml(n)) {
      Ok(x) => x
      Err(_) => panic()
    }
    let r2 = match
      reachable(imported, imported.initial_marking(), capacity + 1) {
      Ok(x) => x
      Err(_) => panic()
    }
    assert_eq(r2.states(), r.states())
  }
}

///|
test "builder rejects control-character names that cannot safely roundtrip" {
  let n = PetriNet::new()
  for name in ["bad\u0000", "bad\nname", "\u{FFFF}"] {
    assert_true(n.add_place(name, 0) is Err(InvalidName))
    assert_true(n.add_transition(name) is Err(InvalidName))
  }
  assert_eq(n.place_count(), 0)
  assert_eq(n.transition_count(), 0)
}
