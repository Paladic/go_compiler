package p

func f() {
	for {
		select {
		default:
			continue
		}
	}
}
