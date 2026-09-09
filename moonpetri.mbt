///|
pub struct Arc {
  place : Int
  transition : Int
  mut weight : Int
}

///|
pub struct Marking {
  priv tokens : Array[Int]
} derive(Eq, Debug)

///|
pub(all) enum PetriError {
  EmptyName
  InvalidName
  NegativeTokens
  InvalidWeight
  InvalidPlace
  InvalidTransition
  InvalidMarking
  NotEnabled
  InvalidMaxStates
  DuplicateName(String)
  TokenOverflow
  SequenceFailed(Int, Int, PetriError)
  ParseError(String)
} derive(Eq, Debug)

///|
struct Transition {
  name : String
  inputs : Array[Arc]
  outputs : Array[Arc]
}

///|
pub struct PetriNet {
  priv places : Array[String]
  priv initial : Array[Int]
  priv transitions : Array[Transition]
  priv pnml_transition_ids : Map[String, Int]
}

///|
pub struct ReachabilityResult {
  priv states : Array[Marking]
  priv predecessors : Array[(Int, Int)?]
  priv deadlock_indices : Array[Int]
  edges : Int
  truncated : Bool
  max_tokens : Int
}

///|
pub fn PetriNet::new() -> PetriNet {
  { places: [], initial: [], transitions: [], pnml_transition_ids: Map([]) }
}

///|
pub fn PetriNet::add_place(
  self : PetriNet,
  name : String,
  tokens : Int,
) -> Result[Int, PetriError] {
  if name.trim() == "" {
    return Err(EmptyName)
  }
  if !valid_name(name) {
    return Err(InvalidName)
  }
  if tokens < 0 {
    return Err(NegativeTokens)
  }
  for n in self.places {
    if n == name {
      return Err(DuplicateName(name))
    }
  }
  let i = self.places.length()
  self.places.push(name)
  self.initial.push(tokens)
  Ok(i)
}

///|
pub fn PetriNet::add_transition(
  self : PetriNet,
  name : String,
) -> Result[Int, PetriError] {
  if name.trim() == "" {
    return Err(EmptyName)
  }
  if !valid_name(name) {
    return Err(InvalidName)
  }
  for t in self.transitions {
    if t.name == name {
      return Err(DuplicateName(name))
    }
  }
  let i = self.transitions.length()
  self.transitions.push({ name, inputs: [], outputs: [] })
  Ok(i)
}

///|
fn add_arc(a : Array[Arc], x : Arc) -> Result[Unit, PetriError] {
  if x.weight <= 0 {
    return Err(InvalidWeight)
  }
  for i in 0..<a.length() {
    if a[i].place == x.place && a[i].transition == x.transition {
      if a[i].weight > 2147483647 - x.weight {
        return Err(TokenOverflow)
      }
      a[i].weight = a[i].weight + x.weight
      return Ok(())
    }
  }
  a.push(x)
  Ok(())
}

///|
pub fn PetriNet::add_input(
  self : PetriNet,
  p : Int,
  t : Int,
  w : Int,
) -> Result[Unit, PetriError] {
  if p < 0 || p >= self.places.length() {
    return Err(InvalidPlace)
  }
  if t < 0 || t >= self.transitions.length() {
    return Err(InvalidTransition)
  }
  add_arc(self.transitions[t].inputs, { place: p, transition: t, weight: w })
}

///|
pub fn PetriNet::add_output(
  self : PetriNet,
  t : Int,
  p : Int,
  w : Int,
) -> Result[Unit, PetriError] {
  if p < 0 || p >= self.places.length() {
    return Err(InvalidPlace)
  }
  if t < 0 || t >= self.transitions.length() {
    return Err(InvalidTransition)
  }
  add_arc(self.transitions[t].outputs, { place: p, transition: t, weight: w })
}

///|
pub fn PetriNet::place_count(self : PetriNet) -> Int {
  self.places.length()
}

///|
pub fn PetriNet::transition_count(self : PetriNet) -> Int {
  self.transitions.length()
}

///|
pub fn PetriNet::place_name(self : PetriNet, id : Int) -> String? {
  if id < 0 || id >= self.places.length() {
    None
  } else {
    Some(self.places[id])
  }
}

///|
pub fn PetriNet::transition_name(self : PetriNet, id : Int) -> String? {
  if id < 0 || id >= self.transitions.length() {
    None
  } else {
    Some(self.transitions[id].name)
  }
}

///|
pub fn PetriNet::initial_marking(self : PetriNet) -> Marking {
  { tokens: self.initial.copy() }
}

///|
fn valid(net : PetriNet, m : Marking) -> Bool {
  m.tokens.length() == net.places.length() && m.tokens.all(fn(x) { x >= 0 })
}

///|
pub fn enabled(net : PetriNet, m : Marking, t : Int) -> Bool {
  if !valid(net, m) || t < 0 || t >= net.transitions.length() {
    return false
  }
  for a in net.transitions[t].inputs {
    if m.tokens[a.place] < a.weight {
      return false
    }
  }
  true
}

///|
pub fn enabled_transitions(net : PetriNet, m : Marking) -> Array[Int] {
  let r = []
  for t in 0..<net.transitions.length() {
    if enabled(net, m, t) {
      r.push(t)
    }
  }
  r
}

///|
pub fn fire(
  net : PetriNet,
  m : Marking,
  t : Int,
) -> Result[Marking, PetriError] {
  if !valid(net, m) {
    return Err(InvalidMarking)
  }
  if t < 0 || t >= net.transitions.length() {
    return Err(InvalidTransition)
  }
  if !enabled(net, m, t) {
    return Err(NotEnabled)
  }
  let n = m.tokens.copy()
  for a in net.transitions[t].inputs {
    n[a.place] = n[a.place] - a.weight
  }
  for a in net.transitions[t].outputs {
    if n[a.place] > 2147483647 - a.weight {
      return Err(TokenOverflow)
    }
    n[a.place] = n[a.place] + a.weight
  }
  Ok({ tokens: n })
}

///|
pub fn fire_sequence(
  net : PetriNet,
  m : Marking,
  seq : Array[Int],
) -> Result[Marking, PetriError] {
  if !valid(net, m) {
    return Err(InvalidMarking)
  }
  let mut x = marking(m.tokens)
  for i in 0..<seq.length() {
    let t = seq[i]
    match fire(net, x, t) {
      Ok(n) => x = n
      Err(e) => return Err(SequenceFailed(i, t, e))
    }
  }
  Ok(x)
}

///|
fn key(m : Marking) -> String {
  m.tokens.map(fn(x) { x.to_string() }).join(",")
}

///|
pub fn reachable(
  net : PetriNet,
  start : Marking,
  max : Int,
) -> Result[ReachabilityResult, PetriError] {
  if max <= 0 {
    return Err(InvalidMaxStates)
  }
  if !valid(net, start) {
    return Err(InvalidMarking)
  }
  let states = [marking(start.tokens)]
  let predecessors : Array[(Int, Int)?] = [None]
  let seen : Map[String, Int] = Map([])
  seen[key(start)] = 0
  let mut head = 0
  let deadlock_indices = []
  let mut edges = 0
  let mut trunc = false
  while head < states.length() {
    let i = head
    head = head + 1
    let transitions = enabled_transitions(net, states[i])
    if transitions.is_empty() {
      deadlock_indices.push(i)
    }
    for t in transitions {
      if edges == 2147483647 {
        return Err(TokenOverflow)
      }
      edges = edges + 1
      let n = match fire(net, states[i], t) {
        Ok(v) => v
        Err(e) => return Err(e)
      }
      if !seen.contains(key(n)) {
        if states.length() >= max {
          trunc = true
        } else {
          seen[key(n)] = states.length()
          states.push(n)
          predecessors.push(Some((i, t)))
        }
      }
    }
  }
  let mut mt = 0
  for m in states {
    for x in m.tokens {
      if x > mt {
        mt = x
      }
    }
  }
  Ok({
    states,
    predecessors,
    deadlock_indices,
    edges,
    truncated: trunc,
    max_tokens: mt,
  })
}

///|
pub fn deadlocks(_net : PetriNet, r : ReachabilityResult) -> Array[Marking] {
  r.deadlock_indices.map(fn(i) { marking(r.states[i].tokens) })
}

///|
pub fn is_bounded(r : ReachabilityResult) -> Bool {
  !r.truncated
}

///|
pub fn shortest_trace(r : ReachabilityResult, target : Marking) -> Array[Int]? {
  for i in 0..<r.states.length() {
    if key(r.states[i]) == key(target) {
      let path : Array[Int] = []
      let mut cursor = i
      while r.predecessors[cursor] is Some((parent, transition)) {
        path.push(transition)
        cursor = parent
      }
      return Some(path.rev())
    }
  }
  None
}

///|
/// Summarize a bounded exploration.
pub struct AnalysisReport {
  states : Int
  edges : Int
  deadlocks : Int
  truncated : Bool
  max_tokens : Int
}

///|
pub fn analysis_report(
  net : PetriNet,
  r : ReachabilityResult,
) -> AnalysisReport {
  {
    states: r.states.length(),
    edges: r.edges,
    deadlocks: deadlocks(net, r).length(),
    truncated: r.truncated,
    max_tokens: r.max_tokens,
  }
}

///|
/// Create a marking with explicit token values.
pub fn marking(tokens : Array[Int]) -> Marking {
  { tokens: tokens.copy() }
}

///|
/// Return a stable textual fingerprint for diagnostics and snapshots.
pub fn marking_fingerprint(m : Marking) -> String {
  m.tokens.map(fn(x) { x.to_string() }).join(",")
}

///|
/// Return a defensive copy, never the marking's backing array.
pub fn Marking::tokens(self : Marking) -> Array[Int] {
  self.tokens.copy()
}

///|
pub fn Marking::token(self : Marking, place : Int) -> Int? {
  if place < 0 || place >= self.tokens.length() {
    None
  } else {
    Some(self.tokens[place])
  }
}

///|
/// Return detached state snapshots in BFS order.
pub fn ReachabilityResult::states(self : ReachabilityResult) -> Array[Marking] {
  self.states.map(fn(m) { marking(m.tokens) })
}

///|
pub fn ReachabilityResult::state_count(self : ReachabilityResult) -> Int {
  self.states.length()
}
