package sample

type Point struct{ X int }

func (p *Point) Set(x int) { p.X = x }
