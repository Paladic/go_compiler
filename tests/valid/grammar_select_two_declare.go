package p

func f() {
	select {
	case a, b := <-ch:
	}
}
