package p

var a <-chan int
var b chan<- chan int
var c = make(<-chan int)
var d = <-chan int(c)
var e = (<-chan int)(c)
var f = <-chan int(c).x
