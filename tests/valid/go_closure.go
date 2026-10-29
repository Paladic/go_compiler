package sample

func test() {
	go func() { work() }()
}
