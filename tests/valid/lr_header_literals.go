package p

func f() {
	if x := struct{}{}; x == x {
	}
	for range []int{} {
	}
	if f := func() {
		for {
			break
		}
	}; f != nil {
	}
	switch x := map[int]int{}; x[0] {
	case 0:
	}
	if x := (T{}); x == x {
	}
}
