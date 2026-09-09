///|
/// Verify model invariants without modifying the net.
pub fn PetriNet::validate(self : PetriNet) -> Result[Unit, Array[PetriError]] {
  let errors : Array[PetriError] = []
  if self.initial.length() != self.places.length() {
    errors.push(InvalidMarking)
  }
  let names : Map[String, Bool] = Map([])
  for name in self.places {
    if name.trim() == "" {
      errors.push(EmptyName)
    }
    if names.contains(name) {
      errors.push(DuplicateName(name))
    }
    names[name] = true
  }
  for tokens in self.initial {
    if tokens < 0 {
      errors.push(NegativeTokens)
    }
  }
  let transitions : Map[String, Bool] = Map([])
  for t in 0..<self.transitions.length() {
    let transition = self.transitions[t]
    if transition.name.trim() == "" {
      errors.push(EmptyName)
    }
    if transitions.contains(transition.name) {
      errors.push(DuplicateName(transition.name))
    }
    transitions[transition.name] = true
    for arcs in [transition.inputs, transition.outputs] {
      let seen : Map[Int, Bool] = Map([])
      for arc in arcs {
        if arc.place < 0 || arc.place >= self.places.length() {
          errors.push(InvalidPlace)
        }
        if arc.transition != t {
          errors.push(InvalidTransition)
        }
        if arc.weight <= 0 {
          errors.push(InvalidWeight)
        }
        if seen.contains(arc.place) {
          errors.push(InvalidWeight)
        }
        seen[arc.place] = true
      }
    }
  }
  if errors.is_empty() {
    Ok(())
  } else {
    Err(errors)
  }
}

///|
/// Resolve a transition's unique domain name, not its PNML serialization ID.
pub fn PetriNet::find_transition(self : PetriNet, name : String) -> Int? {
  for t in 0..<self.transitions.length() {
    if self.transitions[t].name == name {
      return Some(t)
    }
  }
  None
}

///|
test "validation catches corrupted internal fields in stable order" {
  let n = PetriNet::new()
  ignore(n.add_place("p", 1))
  ignore(n.add_transition("t"))
  assert_true(n.validate() is Ok(_))
  n.initial[0] = -1
  assert_eq(n.validate(), Err([NegativeTokens]))
  assert_eq(n.find_transition("t"), Some(0))
  assert_eq(n.find_transition("missing"), None)
}

///|
/// Resolve an original imported PNML ID, independently of display labels.
pub fn PetriNet::find_pnml_transition(self : PetriNet, id : String) -> Int? {
  self.pnml_transition_ids.get(id)
}
