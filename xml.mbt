///|
priv suberror XmlError {
  XmlError(String)
}

///|
priv struct XmlNode {
  name : String
  attrs : Map[String, String]
  children : Array[XmlNode]
  text : String
}

///|
priv struct XmlReader {
  input : String
  mut pos : Int
}

///|
fn XmlReader::starts(self : XmlReader, s : String) -> Bool {
  self.pos + s.length() <= self.input.length() &&
  self.input[self.pos:self.pos + s.length()] == s[:]
}

///|
fn[T] XmlReader::fail(self : XmlReader, message : String) -> T raise XmlError {
  raise XmlError("XML offset \{self.pos}: \{message}")
}

///|
fn XmlReader::space(self : XmlReader) -> Unit {
  while self.pos < self.input.length() {
    let c = self.input[self.pos]
    if c != 32 && c != 9 && c != 10 && c != 13 {
      break
    }
    self.pos += 1
  }
}

///|
fn XmlReader::name(self : XmlReader) -> String raise XmlError {
  let start = self.pos
  while self.pos < self.input.length() {
    let c = self.input[self.pos]
    if !((c >= 65 && c <= 90) ||
      (c >= 97 && c <= 122) ||
      c == 95 ||
      (self.pos > start && ((c >= 48 && c <= 57) || c == 45))) {
      break
    }
    self.pos += 1
  }
  if start == self.pos {
    self.fail("expected unqualified name")
  }
  self.input[start:self.pos].to_owned()
}

///|
fn xml_decode(s : String) -> String raise XmlError {
  let out : Array[String] = []
  let mut i = 0
  while i < s.length() {
    if s[i] == 38 {
      let mut j = i + 1
      while j < s.length() && s[j] != 59 {
        j += 1
      }
      if j == s.length() {
        raise XmlError("unterminated entity")
      }
      let name = s[i:j + 1].to_owned()
      out.push(
        match name {
          "&amp;" => "&"
          "&lt;" => "<"
          "&gt;" => ">"
          "&quot;" => "\""
          "&apos;" => "'"
          _ => raise XmlError("unsupported entity")
        },
      )
      i = j + 1
    } else {
      let c = s[i]
      if c < 32 && c != 9 && c != 10 && c != 13 {
        raise XmlError("invalid control character")
      }
      out.push(s[i:i + 1].to_owned())
      i += 1
    }
  }
  out.join("")
}

///|
fn XmlReader::node(self : XmlReader, depth : Int) -> XmlNode raise XmlError {
  if depth > 16 {
    self.fail("nesting limit exceeded")
  }
  if !self.starts("<") {
    self.fail("expected element")
  }
  self.pos += 1
  let name = self.name()
  let attrs : Map[String, String] = Map([])
  while true {
    let before = self.pos
    self.space()
    if self.starts("/>") {
      self.pos += 2
      return { name, attrs, children: [], text: "" }
    }
    if self.starts(">") {
      self.pos += 1
      break
    }
    if before == self.pos {
      self.fail("expected attribute separator")
    }
    let key = self.name()
    if attrs.contains(key) {
      self.fail("duplicate attribute")
    }
    self.space()
    if !self.starts("=") {
      self.fail("expected equals")
    }
    self.pos += 1
    self.space()
    if self.pos >= self.input.length() {
      self.fail("missing attribute value")
    }
    let quote = self.input[self.pos]
    if quote != 34 && quote != 39 {
      self.fail("expected quoted value")
    }
    self.pos += 1
    let start = self.pos
    while self.pos < self.input.length() && self.input[self.pos] != quote {
      if self.input[self.pos] == 60 {
        self.fail("less-than in attribute")
      }
      self.pos += 1
    }
    if self.pos == self.input.length() {
      self.fail("unterminated attribute")
    }
    attrs[key] = xml_decode(self.input[start:self.pos].to_owned())
    self.pos += 1
  }
  let children = []
  let text : Array[String] = []
  while true {
    if self.pos >= self.input.length() {
      self.fail("unclosed element")
    }
    if self.starts("</") {
      self.pos += 2
      if self.name() != name {
        self.fail("mismatched closing tag")
      }
      self.space()
      if !self.starts(">") {
        self.fail("expected closing bracket")
      }
      self.pos += 1
      break
    }
    if self.starts("<") {
      children.push(self.node(depth + 1))
    } else {
      let start = self.pos
      while self.pos < self.input.length() && self.input[self.pos] != 60 {
        self.pos += 1
      }
      text.push(xml_decode(self.input[start:self.pos].to_owned()))
    }
  }
  { name, attrs, children, text: text.join("") }
}

///|
fn xml_parse(input : String) -> XmlNode raise XmlError {
  if input.length() > 2000000 {
    raise XmlError("input size limit exceeded")
  }
  let r = { input, pos: 0 }
  r.space()
  let declaration = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
  if r.starts(declaration) {
    r.pos += declaration.length()
    r.space()
  }
  let node = r.node(0)
  r.space()
  if r.pos != input.length() {
    r.fail("trailing content")
  }
  node
}

///|
test "strict scanner rejects malformed XML and entities" {
  for
    input in [
      "", "<a>", "<a></b>", "<a/><b/>", "<!DOCTYPE a><a/>", "<a x='1' x='2'/>", "<a>&external;</a>",
      "<a x='<'/>", "<a><b/></c>",
    ] {
    let rejected = try {
      ignore(xml_parse(input))
      false
    } catch {
      _ => true
    }
    assert_true(rejected)
  }
  let n = xml_parse("<a x='&amp;'><b>中文 &lt;值&gt;</b></a>")
  assert_eq(n.attrs["x"], "&")
  assert_eq(n.children[0].text, "中文 <值>")
}
