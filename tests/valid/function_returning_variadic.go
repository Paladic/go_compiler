package sample

func f() func(...int) { return func(xs ...int) {} }
