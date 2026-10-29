package sample

func test() {
	for i := 0; i < 3; i++ {
		for j := 0; j < 3; j++ {
			use(i, j)
		}
	}
}
