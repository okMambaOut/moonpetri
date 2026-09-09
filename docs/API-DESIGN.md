# API design

IDs are stable array positions, insertion order is preserved, and every returned marking owns a copied token array. `reachable` uses BFS and stores the first trace for each fingerprint, making shortest traces deterministic. The hard state cap is explicit; it is not a proof of mathematical boundedness.
