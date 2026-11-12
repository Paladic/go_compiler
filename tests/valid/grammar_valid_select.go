package p

func f() {
	select {
	case x := <-ch:
		g()
	default:
		h()
	}
}
