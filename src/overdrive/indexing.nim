## Indexing routines
##
## Copyright (C) 2025 Trayambak Rai (xtrayambak at disroot dot org)
import pkg/overdrive/[flags, types]

{.push inline.}
when hasAvx2:
  func indexI8*[U: Vectorizable](
      v: Vector[U], i: static int
  ): int8 {.raises: [IndexDefect].} =
    if i > 31:
      raise newException(IndexDefect, "Cannot index " & $i & "th index from Vector!")

    cast[int8](mm256_extract_epi8(v.reg, uint32(i)))

  func indexI16*[U: Vectorizable](
      v: Vector[U], i: static int
  ): int16 {.raises: [IndexDefect].} =
    if i > 15:
      raise newException(IndexDefect, "Cannot index " & $i & "th index from Vector!")

    cast[int16](mm256_extract_epi16(v.reg, uint32(i)))

  func indexI32*[U: Vectorizable](
      v: Vector[U], i: static int
  ): int32 {.raises: [IndexDefect].} =
    if i > 7:
      raise newException(IndexDefect, "Cannot index " & $i & "th index from Vector!")

    cast[int32](mm256_extract_epi32(v.reg, uint32(i)))

  func indexI64*[U: Vectorizable](
      v: Vector[U], i: static int
  ): int64 {.raises: [IndexDefect].} =
    if i > 3:
      raise newException(IndexDefect, "Cannot index " & $i & "th index from Vector!")

    cast[int64](mm256_extract_epi64(v.reg, uint32(i)))

  func indexU8*[U: Vectorizable](
      v: Vector[U], i: static int
  ): uint8 {.inline, raises: [IndexDefect].} =
    cast[uint8](v.indexI8(i))

  func indexU16*[U: Vectorizable](
      v: Vector[U], i: static int
  ): uint16 {.inline, raises: [IndexDefect].} =
    cast[uint16](v.indexI16(i))

  func indexU32*[U: Vectorizable](
      v: Vector[U], i: static int
  ): uint32 {.inline, raises: [IndexDefect].} =
    cast[uint32](v.indexI32(i))

  func indexU64*[U: Vectorizable](
      v: Vector[U], i: static int
  ): uint64 {.inline, raises: [IndexDefect].} =
    cast[uint64](v.indexI64(i))
elif hasSse2:
  func indexI16*[U: Vectorizable](
      v: Vector[U], i: static int
  ): int16 {.raises: [IndexDefect].} =
    if i > 7:
      raise newException(IndexDefect, "Cannot index " & $i & "th index from Vector!")

    cast[int16](mm_extract_epi16(v.reg, uint32(i)))

  func indexU16*[U: Vectorizable](
      v: Vector[U], i: static int
  ): uint16 {.raises: [IndexDefect].} =
    cast[uint16](indexI16(v, i))

  when hasSse41:
    func indexI8*[U: Vectorizable](
        v: Vector[U], i: static int
    ): int8 {.inline, raises: [IndexDefect].} =
      if i > 15:
        raise newException(IndexDefect, "Cannot index " & $i & "th index from Vector!")

      cast[int8](mm_extract_epi8(v.reg, uint32(i)))

    func indexU8*[U: Vectorizable](
        v: Vector[U], i: static int
    ): uint8 {.inline, raises: [IndexDefect].} =
      cast[uint8](indexI8(v, i))

    func indexI32*[U: Vectorizable](
        v: Vector[U], i: static int
    ): int32 {.inline, raises: [IndexDefect].} =
      if i > 3:
        raise newException(IndexDefect, "Cannot index " & $i & "th index from Vector!")

      cast[int32](mm_extract_epi32(v.reg, uint32(i)))

    func indexU32*[U: Vectorizable](
        v: Vector[U], i: static int
    ): uint32 {.inline, raises: [IndexDefect].} =
      cast[uint32](indexI32(v, i))

    func indexI64*[U: Vectorizable](
        v: Vector[U], i: static int
    ): int64 {.inline, raises: [IndexDefect].} =
      if i > 1:
        raise newException(IndexDefect, "Cannot index " & $i & "th index from Vector!")

      cast[int64](mm_extract_epi64(v.reg, uint32(i)))

    func indexU64*[U: Vectorizable](
        v: Vector[U], i: static int
    ): uint64 {.inline, raises: [IndexDefect].} =
      cast[uint64](indexI64(v, i))
  else:
    {.
      warning:
        "This build is configured to not use SSE4.1 ops, all indexing ops for 8-bit, 32-bit and 64-bit integers will use an unoptimal code path. Please compile your program with SSE4.1 as a baseline (-d:sse41) if possible."
    .}
    func indexI8*[U: Vectorizable](
        v: Vector[U], i: static int
    ): int8 {.inline, raises: [IndexDefect].} =
      if i > 15:
        raise newException(IndexDefect, "Cannot index " & $i & "th index from Vector!")

      cast[int8](mm_cvtsi128_si32(mm_srli_si128(v.reg, i)) and 0xFF)

    func indexU8*[U: Vectorizable](
        v: Vector[U], i: static int
    ): uint8 {.inline, raises: [IndexDefect].} =
      cast[uint8](indexI8(v, i))

    func indexI32*[U: Vectorizable](
        v: Vector[U], i: static int
    ): int32 {.inline, raises: [IndexDefect].} =
      if i > 3:
        raise newException(IndexDefect, "Cannot index " & $i & "th index from Vector!")

      mm_cvtsi128_si32(mm_srli_si128(v.reg, i * 4))

    func indexU32*[U: Vectorizable](
        v: Vector[U], i: static int
    ): uint32 {.inline, raises: [IndexDefect].} =
      cast[uint32](indexI32(v, i))

    func indexI64*[U: Vectorizable](
        v: Vector[U], i: static int
    ): int64 {.inline, raises: [IndexDefect].} =
      if i > 1:
        raise newException(IndexDefect, "Cannot index " & $i & "th index from Vector!")

      if i == 0:
        mm_cvtsi128_si64(v.reg)
      else:
        mm_cvtsi128_si64(mm_srli_si128(v.reg, 8))

    func indexU64*[U: Vectorizable](
        v: Vector[U], i: static int
    ): uint64 {.inline, raises: [IndexDefect].} =
      cast[uint64](indexI64(v, i))
elif hasNeon:
  func indexU8*[U: Vectorizable](
      v: Vector[U], i: static int
  ): uint8 {.inline, raises: [IndexDefect].} =
    if i > 15:
      raise newException(IndexDefect, "Cannot index " & $i & "th index from Vector!")

    vgetq_lane_u8(v.reg, i)

  func indexU16*[U: Vectorizable](
      v: Vector[U], i: static int
  ): uint16 {.inline, raises: [IndexDefect].} =
    if i > 15:
      raise newException(IndexDefect, "Cannot index " & $i & "th index from Vector!")

    vgetq_lane_u16(v.reg, i)

  func indexU32*[U: Vectorizable](
      v: Vector[U], i: static int
  ): uint32 {.inline, raises: [IndexDefect].} =
    if i > 7:
      raise newException(IndexDefect, "Cannot index " & $i & "th index from Vector!")

    vgetq_lane_u32(v.reg, i)

  func indexU64*[U: Vectorizable](
      v: Vector[U], i: static int
  ): uint64 {.inline, raises: [IndexDefect].} =
    if i > 1:
      raise newException(IndexDefect, "Cannot index " & $i & "th index from Vector!")

    vgetq_lane_u64(v.reg, i)

{.pop.}

func index*[T: SomeNumber, U: Vectorizable](
    v: Vector[U], typ: typedesc[T], i: static int
): T {.inline.} =
  when typ is int64:
    v.indexI64(i)
  elif typ is int32:
    v.indexI32(i)
  elif typ is int16:
    v.indexI16(i)
  elif typ is int8:
    v.indexI8(i)
  elif typ is uint8:
    v.indexU8(i)
  elif typ is uint16:
    v.indexU16(i)
  elif typ is uint32:
    v.indexU32(i)
  elif typ is uint64:
    v.indexU64(i)
  else:
    {.error: "Cannot extract type from Vector: " & $typ.}
