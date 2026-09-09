///|
pub struct Arc {
  place : Int
  transition : Int
  mut weight : Int
}

///|
pub struct Marking {
  tokens : Array[Int]
} derive(Eq, Debug)

///|
pub enum PetriError {
  EmptyName
  NegativeTokens
  InvalidWeight
  InvalidPlace
  InvalidTransition
  InvalidMarking
  NotEnabled
  InvalidMaxStates
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
  places : Array[String]
  initial : Array[Int]
  transitions : Array[Transition]
}

///|
pub struct ReachabilityResult {
  states : Array[Marking]
  traces : Array[Array[Int]]
  edges : Int
  truncated : Bool
  max_tokens : Int
}

///|
pub fn PetriNet::new() -> PetriNet {
  { places: [], initial: [], transitions: [] }
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
  if tokens < 0 {
    return Err(NegativeTokens)
  }
  for n in self.places {
    if n == name {
      return Err(EmptyName)
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
  for t in self.transitions {
    if t.name == name {
      return Err(EmptyName)
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
  m.tokens.length() == net.places.length()
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
  let mut x = m
  for t in seq {
    match fire(net, x, t) {
      Ok(n) => x = n
      Err(e) => return Err(e)
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
  let states = [start]
  let traces : Array[Array[Int]] = [[]]
  let q = [0]
  let seen : Map[String, Int] = Map([])
  seen[key(start)] = 0
  let mut head = 0
  let mut edges = 0
  let mut trunc = false
  while head < q.length() {
    let i = q[head]
    head = head + 1
    for t in enabled_transitions(net, states[i]) {
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
          let tr = traces[i].copy()
          tr.push(t)
          traces.push(tr)
          q.push(states.length() - 1)
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
  Ok({ states, traces, edges, truncated: trunc, max_tokens: mt })
}

///|
pub fn deadlocks(net : PetriNet, r : ReachabilityResult) -> Array[Marking] {
  let out = []
  for m in r.states {
    if enabled_transitions(net, m).length() == 0 {
      out.push(m)
    }
  }
  out
}

///|
pub fn is_bounded(r : ReachabilityResult) -> Bool {
  !r.truncated
}

///|
pub fn shortest_trace(r : ReachabilityResult, target : Marking) -> Array[Int]? {
  for i in 0..<r.states.length() {
    if key(r.states[i]) == key(target) {
      return Some(r.traces[i].copy())
    }
  }
  None
}
