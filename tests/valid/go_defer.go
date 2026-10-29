package sample

func test() {
	go worker(1)
	defer cleanup()
}
