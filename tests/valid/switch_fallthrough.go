package sample

func test() {
	switch x {
	case 1:
		f()
		fallthrough
	case 2:
		g()
	}
}
