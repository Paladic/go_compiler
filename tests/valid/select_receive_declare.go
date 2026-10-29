package sample

func test() {
	select {
	case value, ok := <-ch:
		use(value, ok)
	}
}
