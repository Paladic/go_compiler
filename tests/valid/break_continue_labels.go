package sample

func test() {
Outer:
	for {
		for {
			continue Outer
		}
		break Outer
	}
	goto Done
Done:
}
