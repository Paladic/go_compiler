package sample

type T struct {
	a, b int
	*Other
	pkg.Base
	Name string `json:"name"`
}
