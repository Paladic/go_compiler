package p

func f() {
	switch v := x.(type) {
	case int:
		g()
	default:
		h()
	}
}
