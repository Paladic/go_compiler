package p

func f() {
	select {
	case _, _ = <-ch:
	}
}
