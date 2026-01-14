import pkg/overdrive, pkg/pretty

var c: Vector[uint8]
c.store(0x80)

var target: Vector[uint8]
target.store(cast[seq[uint8]]("hi"))

let msk = mask(target, c)
assert not allZero(target, c)
