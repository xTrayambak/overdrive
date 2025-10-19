import std/[random, bitops]
import pkg/overdrive
import pkg/benchy
import pkg/pretty

func ofind*(s: string, c: char): int =
  var target: Vector[char]
  target.store(c)

  var i = 0
  let cap = target.capacity

  while i + cap <= s.len:
    var blk: Vector[char]
    blk.store(s[i].addr)

    let masked = blk.mask(target)
    if masked != 0:
      let offset = countTrailingZeroBits(masked)
      return i + offset

    i += cap

  while i < s.len:
    if s[i] == c:
      return i

    inc i

  return -1

func sfind*(s: string, c: char): int =
  for i, ch in s:
    if ch == c:
      return i

  -1

var strs: array[512, string]
for i in 0 ..< 512:
  let size = rand(32 .. 512)
  strs[i].setLen(size)

  for c in 0 ..< size:
    strs[i][c] = cast[char](rand(65 .. 122))

echo "> starting benchmark"

# We won't benchmark against strutils.find() because that calls into memchr
# in most cases, and that's leaps more optimized than our casual little overdrive
# example

debugEcho "overdrive w/ " & $getBackend()

# Force both of them to scan until the end of the string
timeIt "naive find()":
  for str in strs:
    let v {.used, volatile.} = sfind(str, '\0')

timeIt "optimized find()":
  for str in strs:
    let v {.used, volatile.} = ofind(str, '\0')
