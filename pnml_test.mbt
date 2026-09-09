///|
test "PNML imports forward arcs labels tokens and weights" {
  let input = "<pnml><net id='n'><arc id='a' source='p' target='t'><inscription><text>2</text></inscription></arc><place id='p'><name><text>缓冲</text></name><initialMarking><text>3</text></initialMarking></place><transition id='t'/></net></pnml>"
  let n = match parse_pnml(input) {
    Ok(n) => n
    Err(_) => panic()
  }
  assert_eq(n.place_name(0), Some("缓冲"))
  let next = match fire(n, n.initial_marking(), 0) {
    Ok(m) => m
    Err(_) => panic()
  }
  assert_eq(marking_fingerprint(next), "1")
}

///|
test "PNML rejects unsupported or ambiguous models" {
  for
    body in [
      "<place/>", "<place id='p'/><transition id='p'/>", "<place id='p'><initialMarking><text>-1</text></initialMarking></place>",
      "<place id='p'><initialMarking><text>2147483648</text></initialMarking></place>",
      "<place id='p'><initialMarking><text>red</text></initialMarking></place>",
      "<place id='p'><name><text>A</text></name><name><text>B</text></name></place>",
      "<place id='p'/><transition id='t'/><arc id='a' source='p' target='t'><inscription><text>0</text></inscription></arc>",
      "<arc id='a' source='missing' target='t'/><transition id='t'/>", "<place id='p'/><place id='q'/><arc id='a' source='p' target='q'/>",
      "<toolspecific/>", "<page id='hierarchy'/>", "<transition id='t' time='1'/>",
    ] {
    assert_true(
      parse_pnml("<pnml><net id='n'>" + body + "</net></pnml>") is Err(_),
    )
  }
  for
    input in [
      "<pnml/>", "<pnml><net id='a'/><net id='b'/></pnml>", "<pnml xmlns='anything'><net id='n'/></pnml>",
    ] {
    assert_true(parse_pnml(input) is Err(_))
  }
}

///|
test "canonical PNML roundtrip preserves semantics and escapes names" {
  let n = PetriNet::new()
  let p = match n.add_place("缓冲<&\"'>", 3) {
    Ok(x) => x
    Err(_) => panic()
  }
  let t = match n.add_transition("消费&生产") {
    Ok(x) => x
    Err(_) => panic()
  }
  assert_true(n.add_input(p, t, 2) is Ok(_))
  assert_true(n.add_output(t, p, 1) is Ok(_))
  let text = serialize_pnml(n)
  let copy = match parse_pnml(text) {
    Ok(x) => x
    Err(_) => panic()
  }
  assert_eq(serialize_pnml(copy), text)
  assert_eq(copy.place_name(0), n.place_name(0))
  assert_eq(copy.transition_name(0), n.transition_name(0))
  assert_eq(
    fire(copy, copy.initial_marking(), 0),
    fire(n, n.initial_marking(), 0),
  )
  let empty = match parse_pnml(serialize_pnml(PetriNet::new())) {
    Ok(x) => x
    Err(_) => panic()
  }
  assert_eq(empty.place_count(), 0)
}
