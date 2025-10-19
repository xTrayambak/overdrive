import pkg/overdrive, pkg/pretty

var c: Vector[char]
c.store('!')

var target: Vector[char]
target.store("ts so tuff!")

let msk = mask(target, c)
assert msk == 1024, $msk
