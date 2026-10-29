package sample

func sum[T, U ~int | ~float64](a T, b U) T { return a }
