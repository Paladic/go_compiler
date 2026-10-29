package main

var a = 10
var b = 20

var sum = a + b
var sub = a - b
var mul = a * b
var div = a / b
var mod = a % b

var priority1 = 10 + 20 * 3
var priority2 = (10 + 20) * 3
var priority3 = 10 * 20 + 3

var shiftLeft = a << 2
var shiftRight = b >> 1

var bitAnd = a & b
var bitOr = a | b
var bitXor = a ^ b
var bitClear = a &^ b

var equal = a == b
var notEqual = a != b;
var less = a < b
var lessEqual = a <= b
var greater = a > b
var greaterEqual = a >= b

var logicalAnd = a < b && b > 0
var logicalOr = a == 10 || b == 10

var complex = a + b * 2 > 30 && a != 0 || b == 20

var unaryPlus = +a
var unaryMinus = -a
var unaryNot = !a
var unaryXor = ^a
var unaryPointer = *a
var unaryAddress = &a
var receive = <-a

var nested = (((a + b) * 2) > 10)