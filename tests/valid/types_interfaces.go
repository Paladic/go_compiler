package sample

type I interface {
	Read(p []byte) (int, error)
	Other
	~int | ~string
}
