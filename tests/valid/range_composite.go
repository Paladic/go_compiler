package sample

func test() {
	for _, v := range []Point{{X: 1}, {X: 2}} {
		use(v)
	}
}
