package p

func f(x any) {
	switch ; v := x.(type) {
	case int:
		_ = v
	default:
	}
}
