import std/unittest
import pkg/overdrive

suite "basic tests":
  test "add two u8 vectors":
    var a, b: Vector[uint8]
    a.store(4'u8)
    b.store(4'u8)

    let c = a + b

    check(c.index(uint8, 0) == 8'u8)

  test "add two u16 vectors":
    var a, b: Vector[uint16]
    a.store(512'u16)
    b.store(512'u16)

    let c = a + b
    check(c.index(uint16, 0) == 1024'u16)

  test "add two u32 vectors":
    var a, b: Vector[uint32]
    a.store(65536'u32)
    b.store(65536'u32)

    let c = a + b
    check(c.index(uint32, 0) == 131072'u32)

  test "add two u64 vectors":
    var a, b: Vector[uint64]
    a.store(4294967295'u64)
    b.store(4294967295'u64)

    let c = a + b
    check(c.index(uint64, 0) == 8589934590'u64)
