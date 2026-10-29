package sample

func test() {
	for value := range func(yield func(int) bool) { yield(1) } {
	}
}
