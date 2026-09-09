///|
/// A truncated finite search proves neither boundedness nor unboundedness.
pub(all) enum Boundedness {
  ProvenBounded
  Unknown
} derive(Eq, Debug)

///|
pub fn boundedness(result : ReachabilityResult) -> Boundedness {
  if result.truncated {
    Unknown
  } else {
    ProvenBounded
  }
}

///|
/// Observed maxima per place, not proven bounds unless search is complete.
pub fn observed_place_maxima(result : ReachabilityResult) -> Array[Int] {
  let maxima = result.states[0].tokens.copy()
  for state in result.states {
    for p in 0..<maxima.length() {
      if state.tokens[p] > maxima[p] {
        maxima[p] = state.tokens[p]
      }
    }
  }
  maxima
}

///|
/// Deadlock witnesses and their shortest traces in discovery order.
pub fn deadlock_traces(
  result : ReachabilityResult,
) -> Array[(Marking, Array[Int])] {
  result.deadlock_indices.map(fn(i) {
    let state = marking(result.states[i].tokens)
    (state, shortest_trace(result, state).unwrap())
  })
}

///|
test "deadlock evidence is frozen even if builder is extended later" {
  let n = PetriNet::new()
  ignore(n.add_place("p", 1))
  let t = match n.add_transition("consume") {
    Ok(t) => t
    Err(_) => panic()
  }
  ignore(n.add_input(0, t, 1))
  let r = match reachable(n, n.initial_marking(), 10) {
    Ok(r) => r
    Err(_) => panic()
  }
  assert_eq(boundedness(r), ProvenBounded)
  assert_eq(observed_place_maxima(r), [1])
  assert_eq(deadlock_traces(r), [(marking([0]), [t])])
  ignore(n.add_transition("always-enabled"))
  assert_eq(deadlocks(n, r), [marking([0])])
}

///|
test "truncated frontier is not a deadlock or a proof of unboundedness" {
  let n = PetriNet::new()
  ignore(n.add_place("p", 0))
  ignore(n.add_transition("grow"))
  ignore(n.add_output(0, 0, 1))
  let r = match reachable(n, n.initial_marking(), 2) {
    Ok(r) => r
    Err(_) => panic()
  }
  assert_eq(boundedness(r), Unknown)
  assert_eq(deadlock_traces(r), [])
  assert_eq(observed_place_maxima(r), [1])
}
