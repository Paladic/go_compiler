package sample

func test() {
	select {
	case ch <- value:
		use(value)
	default:
	}
}
