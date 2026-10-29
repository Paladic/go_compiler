package p

type A[P *C,] int
type B[P [2]int] int
type C[P *[2]int] int
type D[P []int] int

func f[P *C]() {}
