package p

func f() {
	switch x {
	case 1:
		if false {
			goto L
		}
	L:
		fallthrough
	default:
	}
}
