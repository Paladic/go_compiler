package sample

func test() {
	select {
	case <-ch:
		done()
	}
}
