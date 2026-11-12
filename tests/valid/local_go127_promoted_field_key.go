package p

type Inner struct{ Value int };type Outer struct{Inner};var x=Outer{Value: 20}
