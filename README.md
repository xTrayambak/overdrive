# overdrive
Overdrive is a high-performance SIMD abstraction library for Nim that aims to abstract away SIMD operations behind a neat, (mostly) safe Nim-like API.

The gist is that it lets you write SIMD code that runs on a lot of stuff, ranging from your desktop/laptop to your Android phone, to your tablet, to your smart TV.

# features
- [X] Store
- [X] Indexing
- [X] Masking
- [ ] Averages
- [ ] Insertion
- [ ] Zero/one testing

# roadmap
- [X] AVX2 support
- [X] SSE4.1 support
- [X] SSE3 support
- [X] SSE2 support
- [X] Scalar fallback support (see section "Scalar Fallback")
- [X] Multi-arch CI setup (chore)
- [X] NEON support
- [ ] RVV support
- [ ] WASM SIMD support (for Emscripten target)

# basic example
Here, we can see a basic example of using Overdrive to write a simple string-find function.

```nim
func find(s: string, c: char): int =
  var target: Vector[char]
  target.store(c) # Load the character we're searching for into a register

  var i = 0
  let cap = target.capacity

  while i + cap <= s.len:
    # If there are more than or 32 bytes/characters ahead,
    var blk: Vector[char]
    blk.store(s[i].addr) # Load the string from i ..< i + 32

    let masked = blk.mask(target) # Mask the block against the target
    if masked != 0: # If masked were to be zero, it'd mean `c` is not in this block.
      let offset = countTrailingZeroBits(masked)
        # Get the first offset at which `c` occurs in the block
      return i + offset

    i += cap

  # Process the bytes that didn't fit in the register
  while i < s.len:
    if s[i] == c:
      return i

    inc i
  
  # We couldn't find c
  return -1
```
Overdrive neatly abstracts away the subtleties and pain-points of using vector intrinsics away from the programmer, acting as a write-once, run-anywhere SIMD library like Google's [Highway](https://github.com/google/highway) but in pure, idiomatic Nim with **next to zero performance cost** thanks to the use of templates and compile-time ISA selection.

# installation
To use Overdrive in your program, run the following:

## neo
Neo can be downloaded [here](https://github.com/xTrayambak/neo).
However, you aren't forced to use it.

```bash
$ neo add gh:xTrayambak/overdrive
```

## nimble
```bash
$ nimble add https://github.com/xTrayambak/overdrive
```

# scalar fallback
Overdrive can utilize a scalar backend when no supported ISA is usable, but this is more of a last-resort and should be avoided as much as possible. It is _horribly_ slow and is not guaranteed to be correct (for now). You are recommended to utilize the `getBackend()` function to implement your own scalar algorithm implementations when SIMD acceleration is not present.

```nim
when getBackend() != VInstSet.Scalar:
  # SIMD accelerated path
  # ...
else:
  # Scalar path
  # ...
```

The scalar fallback uses an `array[N, U]`. `N` can be specified via the compile-time flag `-d:OverdriveScalarRegSize`, and it is 32 by default.
