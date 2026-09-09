///|
/// Deterministic JSON summary; false boundedness is unknown when truncated.
pub fn AnalysisReport::to_json(self : AnalysisReport) -> String {
  "{\"states\":\{self.states},\"edges\":\{self.edges},\"deadlocks\":\{self.deadlocks},\"max_tokens\":\{self.max_tokens},\"truncated\":\{self.truncated}}"
}

///|
/// Pure CLI engine: file access and process exit live in cmd/moonpetri.
pub fn run_command(
  command : String,
  input : String,
  args : Array[String],
) -> Result[String, Array[PetriError]] {
  let net = match parse_pnml(input) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  match net.validate() {
    Ok(_) => ()
    Err(e) => return Err(e)
  }
  let start = net.initial_marking()
  match command {
    "validate" => {
      if !args.is_empty() {
        return Err([ParseError("validate takes no options")])
      }
      Ok(
        "valid places=\{net.place_count()} transitions=\{net.transition_count()} enabled=\{enabled_transitions(net,start).length()}",
      )
    }
    "fire" => {
      let seq = []
      for name in args {
        let found = match net.find_pnml_transition(name) {
          Some(t) => Some(t)
          None => net.find_transition(name)
        }
        match found {
          Some(t) => seq.push(t)
          None => return Err([ParseError("unknown transition: \{name}")])
        }
      }
      match fire_sequence(net, start, seq) {
        Ok(m) => Ok("marking=[\{marking_fingerprint(m)}]")
        Err(e) => Err([e])
      }
    }
    "explore" | "report" => {
      let max = if args.is_empty() {
        1000
      } else if args.length() == 2 && args[0] == "--max-states" {
        natural(args[1]) catch {
          _ => return Err([InvalidMaxStates])
        }
      } else {
        return Err([ParseError("expected --max-states INTEGER")])
      }
      let result = match reachable(net, start, max) {
        Ok(r) => r
        Err(e) => return Err([e])
      }
      let report = analysis_report(net, result)
      if command == "report" {
        Ok(report.to_json())
      } else {
        Ok(
          "states=\{report.states} edges=\{report.edges} deadlocks=\{report.deadlocks} max_tokens=\{report.max_tokens} truncated=\{report.truncated}",
        )
      }
    }
    _ => Err([ParseError("expected validate, explore, fire or report")])
  }
}

///|
test "command engine validates options and emits stable structured output" {
  let input = "<pnml><net id='n'><place id='p'/></net></pnml>"
  assert_eq(
    run_command("validate", input, []),
    Ok("valid places=1 transitions=0 enabled=0"),
  )
  assert_eq(run_command("fire", input, []), Ok("marking=[0]"))
  assert_eq(
    run_command("report", input, []),
    Ok(
      "{\"states\":1,\"edges\":0,\"deadlocks\":1,\"max_tokens\":0,\"truncated\":false}",
    ),
  )
  assert_true(run_command("fire", input, ["missing"]) is Err(_))
  assert_true(run_command("bad", input, []) is Err(_))
  assert_true(run_command("report", input, ["--max-states", "0"]) is Err(_))
  assert_true(run_command("explore", input, ["--max-states", "-1"]) is Err(_))
  assert_true(run_command("validate", "<pnml>", []) is Err(_))
}

///|
test "CLI resolves PNML transition IDs before human-readable labels" {
  let input = "<pnml><net id='n'><place id='p'><initialMarking><text>1</text></initialMarking></place><transition id='t_consume'><name><text>消费</text></name></transition><arc id='a' source='p' target='t_consume'/></net></pnml>"
  assert_eq(run_command("fire", input, ["t_consume"]), Ok("marking=[0]"))
  assert_eq(run_command("fire", input, ["消费"]), Ok("marking=[0]"))
  let n = match parse_pnml(input) {
    Ok(n) => n
    Err(_) => panic()
  }
  assert_eq(n.find_pnml_transition("t_consume"), Some(0))
  assert_eq(n.find_transition("消费"), Some(0))
  assert_eq(n.find_transition("t_consume"), None)
}
