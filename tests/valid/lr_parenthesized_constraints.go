package sample

// Keep these parentheses: this tests LR disambiguation before gofmt normalization.
type Generic[P(C),] int
type Alias[P(C),] = int
