import pathlib, subprocess
p=pathlib.Path('moonpetri_test.mbt')
tests=[
'''test "duplicate arcs merge" { let n=PetriNet::new(); let p=expect_ok(n.add_place("p",2)); let t=expect_ok(n.add_transition("t")); expect_ok(n.add_input(p,t,1)); expect_ok(n.add_input(p,t,1)); assert_true(enabled(n,n.initial_marking(),t)) }''',
'''test "disabled transition cannot fire" { let n=PetriNet::new(); let p=expect_ok(n.add_place("p",0)); let t=expect_ok(n.add_transition("t")); expect_ok(n.add_input(p,t,1)); assert_true(fire(n,n.initial_marking(),t) is Err(_)) }''',
'''test "sequence applies in order" { let n=PetriNet::new(); let p=expect_ok(n.add_place("p",1)); let q=expect_ok(n.add_place("q",0)); let t=expect_ok(n.add_transition("move")); expect_ok(n.add_input(p,t,1)); expect_ok(n.add_output(t,q,1)); let m=expect_ok(fire_sequence(n,n.initial_marking(),[t])); assert_eq(m.tokens[q],1) }''',
'''test "state cap result is deterministic" { let n=PetriNet::new(); let p=expect_ok(n.add_place("p",1)); let t=expect_ok(n.add_transition("loop")); expect_ok(n.add_input(p,t,1)); expect_ok(n.add_output(t,p,1)); let r=expect_ok(reachable(n,n.initial_marking(),1)); assert_false(r.truncated) }''',
'''test "shortest trace starts empty" { let n=PetriNet::new(); expect_ok(n.add_place("p",0)); let r=expect_ok(reachable(n,n.initial_marking(),4)); assert_eq(shortest_trace(r,n.initial_marking()).unwrap().length(),0) }''',
'''test "inspection names are stable" { let n=PetriNet::new(); expect_ok(n.add_place("p",0)); expect_ok(n.add_transition("t")); assert_eq(n.place_count(),1); assert_eq(n.transition_count(),1); assert_eq(n.place_name(0).unwrap(),"p"); assert_eq(n.transition_name(0).unwrap(),"t") }''']
for i,t in enumerate(tests,1):
 p.open('a').write('\n'+t+'\n')
 subprocess.run(['moon','fmt'],check=True,stdout=subprocess.DEVNULL)
 subprocess.run(['moon','test','--target','wasm-gc'],check=True,stdout=subprocess.DEVNULL)
 subprocess.run(['git','add','.'],check=True)
 subprocess.run(['git','commit','-m',f'test: add semantic regression case {i}'],check=True,stdout=subprocess.DEVNULL)
