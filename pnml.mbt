pub fn parse_pnml(_input : String) -> Result[PetriNet, Array[PetriError]] { Err([ParseError("PNML subset parser is not yet available")]) }
pub fn serialize_pnml(_net : PetriNet) -> String { "<pnml><net id=\"moonpetri\"></net></pnml>" }
