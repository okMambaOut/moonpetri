///|
fn[T] require(result : Result[T, @petri.PetriError]) -> T {
  match result {
    Ok(value) => value
    Err(error) => abort(error.to_repr().to_string())
  }
}

///|
fn main {
  let net = @petri.PetriNet::new()
  let free = require(net.add_place("free", 2))
  let buffer = require(net.add_place("buffer", 0))
  let produce = require(net.add_transition("produce"))
  let consume = require(net.add_transition("consume"))
  require(net.add_input(free, produce, 1))
  require(net.add_output(produce, buffer, 1))
  require(net.add_input(buffer, consume, 1))
  require(net.add_output(consume, free, 1))
  let result = require(@petri.reachable(net, net.initial_marking(), 100))
  let target = @petri.marking([0, 2])
  let trace = @petri.shortest_trace(result, target).unwrap()
  if trace != [produce, produce] {
    abort("unexpected shortest trace")
  }
  if require(@petri.fire_sequence(net, net.initial_marking(), trace)) != target {
    abort("trace does not replay")
  }
  println(@petri.analysis_report(net, result).to_json())
  println("shortest_trace=[\{trace.map(fn(t) { t.to_string() }).join(",")}]")
}
