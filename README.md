# MoonPetri

MoonPetri is a pure MoonBit library for deterministic discrete Petri-net modeling and bounded reachability analysis.

## What it provides

- Places, transitions, and weighted input/output arcs
- Initial markings and immutable-by-convention token arrays
- Enabled-transition checks and firing semantics
- Firing sequences with explicit failure results
- Deterministic breadth-first reachability exploration
- Stable marking fingerprints and shortest traces
- Deadlock detection and structured exploration reports
- Small, offline, dependency-free core suitable for tests and teaching

## Quick example

```moonbit
let net = @moonpetri.PetriNet::new()
let buffer = net.add_place("buffer", 1).unwrap()
let consume = net.add_transition("consume").unwrap()
net.add_input(buffer, consume, 1).unwrap()
let result = @moonpetri.fire(net, net.initial_marking(), consume).unwrap()
assert_eq(result.tokens[buffer], 0)
```

## Design boundaries

MoonPetri is not an HTTP library, FSM framework, workflow engine, SMT solver, GUI, or timed/stochastic/coloured Petri-net implementation. The current PNML API deliberately reports unsupported syntax rather than pretending to parse arbitrary XML; the core modeling and analysis APIs are the stable focus of version 0.1.0.

## Verification

```text
moon check --target wasm-gc --deny-warn
moon test --target wasm-gc
```

The repository currently contains 10 passing tests. CI configuration is in `.github/workflows/ci.yml`.

## Contributing

Contributions from **okmanba** are welcome. Please read `CONTRIBUTING.md`, preserve deterministic behavior, add regression tests, and run the local verification commands before submitting changes.

## License

MIT. See `LICENSE`.
