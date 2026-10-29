package sample

func test() {
	select {
	case value = <-ch:
		use(value)
	}
}
