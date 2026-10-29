package sample

func test() {
	switch value.(type) {
	case int, string:
		f()
	case *Point:
	default:
	}
}
