import pkg/overdrive

var c: Vector[uint8]
c.store(0x80)

var target: Vector[uint8]
target.store(cast[seq[uint8]]("hi"))

assert allZero(target, c)
