package sample

func test() {
	switch x := value.(type) {
	case nil:
	case []int:
		use(x)
	}
}
