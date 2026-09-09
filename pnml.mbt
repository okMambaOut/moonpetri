///|
fn XmlNode::shape(
  self : XmlNode,
  attrs : Array[String],
  children : Array[String],
) -> Unit raise XmlError {
  for key, _ in self.attrs {
    if !attrs.contains(key) {
      raise XmlError("unsupported attribute \{key} on \{self.name}")
    }
  }
  for child in self.children {
    if !children.contains(child.name) {
      raise XmlError("unsupported element \{child.name} in \{self.name}")
    }
  }
  if self.name != "text" && self.text.trim() != "" {
    raise XmlError("unexpected text in \{self.name}")
  }
}

///|
fn XmlNode::required(self : XmlNode, key : String) -> String raise XmlError {
  match self.attrs.get(key) {
    Some(s) if s.trim() != "" => s
    _ => raise XmlError("missing \{key} on \{self.name}")
  }
}

///|
fn XmlNode::value(
  self : XmlNode,
  name : String,
  default : String,
) -> String raise XmlError {
  let found = self.children.filter(fn(c) { c.name == name })
  if found.length() == 0 {
    return default
  }
  if found.length() != 1 {
    raise XmlError("duplicate \{name}")
  }
  let wrapper = found[0]
  wrapper.shape([], ["text"])
  if wrapper.children.length() != 1 {
    raise XmlError("expected one text in \{name}")
  }
  let text = wrapper.children[0]
  text.shape([], [])
  text.text
}

///|
fn natural(s : String) -> Int raise XmlError {
  let text = s.trim().to_owned()
  if text == "" {
    raise XmlError("expected nonnegative decimal integer")
  }
  let mut n = 0
  for i in 0..<text.length() {
    let c = text[i].to_int() - 48
    if c < 0 || c > 9 {
      raise XmlError("expected nonnegative decimal integer")
    }
    if n > (2147483647 - c) / 10 {
      raise XmlError("integer overflow")
    }
    n = n * 10 + c
  }
  n
}

///|
fn[T] pnml_result(r : Result[T, PetriError]) -> T raise XmlError {
  match r {
    Ok(x) => x
    Err(e) => raise XmlError("model error: \{e.to_repr()}")
  }
}

///|
fn load_pnml(input : String) -> PetriNet raise XmlError {
  let root = xml_parse(input)
  if root.name != "pnml" {
    raise XmlError("expected pnml root")
  }
  root.shape([], ["net"])
  if root.children.length() != 1 {
    raise XmlError("expected exactly one net")
  }
  let model = root.children[0]
  model.shape(["id", "type"], ["place", "transition", "arc"])
  ignore(model.required("id"))
  if model.attrs.get("type") is Some(t) {
    if t != "http://www.pnml.org/version-2009/grammar/ptnet" {
      raise XmlError("unsupported net type")
    }
  }
  let net = PetriNet::new()
  let ids : Map[String, Bool] = Map([])
  let places : Map[String, Int] = Map([])
  let transitions : Map[String, Int] = Map([])
  for node in model.children {
    let id = node.required("id")
    if ids.contains(id) {
      raise XmlError("duplicate id \{id}")
    }
    ids[id] = true
    match node.name {
      "place" => {
        node.shape(["id"], ["name", "initialMarking"])
        places[id] = pnml_result(
          net.add_place(
            node.value("name", id),
            natural(node.value("initialMarking", "0")),
          ),
        )
      }
      "transition" => {
        node.shape(["id"], ["name"])
        transitions[id] = pnml_result(
          net.add_transition(node.value("name", id)),
        )
      }
      "arc" => node.shape(["id", "source", "target"], ["inscription"])
      _ => raise XmlError("unsupported node")
    }
  }
  for node in model.children {
    if node.name == "arc" {
      let source = node.required("source")
      let target = node.required("target")
      let weight = natural(node.value("inscription", "1"))
      match
        (
          places.get(source),
          transitions.get(target),
          transitions.get(source),
          places.get(target),
        ) {
        (Some(p), Some(t), _, _) => pnml_result(net.add_input(p, t, weight))
        (_, _, Some(t), Some(p)) => pnml_result(net.add_output(t, p, weight))
        _ => raise XmlError("arc must join a declared place and transition")
      }
    }
  }
  net
}

///|
/// Parse the documented flat, namespace-free PNML subset. First error wins.
pub fn parse_pnml(input : String) -> Result[PetriNet, Array[PetriError]] {
  Ok(load_pnml(input)) catch {
    XmlError(message) => Err([ParseError(message)])
  }
}

///|
fn xml_escape(s : String) -> String {
  s
  .replace(old="&", new="&amp;")
  .replace(old="<", new="&lt;")
  .replace(old=">", new="&gt;")
  .replace(old="\"", new="&quot;")
  .replace(old="'", new="&apos;")
}

///|
/// Emit canonical flat PNML with generated IDs and preserved model order.
pub fn serialize_pnml(net : PetriNet) -> String {
  let out = [
    "<pnml><net id=\"moonpetri\" type=\"http://www.pnml.org/version-2009/grammar/ptnet\">",
  ]
  for p in 0..<net.places.length() {
    out.push(
      "<place id=\"p\{p}\"><name><text>\{xml_escape(net.places[p])}</text></name><initialMarking><text>\{net.initial[p]}</text></initialMarking></place>",
    )
  }
  for t in 0..<net.transitions.length() {
    out.push(
      "<transition id=\"t\{t}\"><name><text>\{xml_escape(net.transitions[t].name)}</text></name></transition>",
    )
  }
  let mut id = 0
  for t in 0..<net.transitions.length() {
    for a in net.transitions[t].inputs {
      out.push(
        "<arc id=\"a\{id}\" source=\"p\{a.place}\" target=\"t\{t}\"><inscription><text>\{a.weight}</text></inscription></arc>",
      )
      id += 1
    }
    for a in net.transitions[t].outputs {
      out.push(
        "<arc id=\"a\{id}\" source=\"t\{t}\" target=\"p\{a.place}\"><inscription><text>\{a.weight}</text></inscription></arc>",
      )
      id += 1
    }
  }
  out.push("</net></pnml>")
  out.join("\n")
}
