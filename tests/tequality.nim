import pkg/overdrive

var a, b: Vector[char]
a.store("apple")
b.store('a')

let c = a == b

echo c.index(uint8, 0)
echo c.index(uint8, 1)
echo c.index(uint8, 2)
echo c.index(uint8, 3)
echo c.index(uint8, 4)
