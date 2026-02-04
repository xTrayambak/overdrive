## Masking routines
##
## Copyright (C) 2025 Trayambak Rai (xtrayambak at disroot dot org)
import pkg/overdrive/[flags, types]

when hasAvx2:
  template mask8Avx2Impl*(vec: M256i, against: M256i): int32 =
    mm256_movemask_epi8(mm256_cmpeq_epi8(vec, against))

  template mask16Avx2Impl*(vec: M256i, against: M256i): int32 =
    mm256_movemask_epi8(mm256_cmpeq_epi16(vec, against))

  template mask32Avx2Impl*(vec: M256i, against: M256i): int32 =
    mm256_movemask_epi8(mm256_cmpeq_epi32(vec, against))

  template mask64Avx2Impl*(vec: M256i, against: M256i): int32 =
    mm256_movemask_epi8(mm256_cmpeq_epi64(vec, against))

  template moveMaskAvx2Impl*(vec: M256i): int32 =
    mm256_movemask_epi8(vec)

when hasNeon:
  # Extra intrinsics nimsimd doesn't wrap.
  {.push importc, header: "arm_neon.h".}

  func vsraq_n_u16*(a, b: uint16x8, n: int32): uint16x8
  func vsraq_n_u32*(a, b: uint32x4, n: int32): uint32x4
  func vsraq_n_u64*(a, b: uint64x2, n: int32): uint64x2
  func vreinterpretq_u32_u16*(v: uint16x8): uint32x4
  func vreinterpretq_u8_u64*(v: uint64x2): uint8x16
  func vreinterpretq_u8_u16*(v: uint16x8): uint8x16

  {.pop.}

  template moveMaskNeonImpl(input: uint8x16): int32 =
    # Source: https://stackoverflow.com/a/58381188

    # Shift out everything but the sign bits
    let highBits = vreinterpretq_u16_u8(vshrq_n_u8(input, 7))

    # Merge the even lanes together with vsra. The '??' bytes are garbage.
    # vsri could also be used, but it is slightly slower on aarch64.
    let paired16 = vreinterpretq_u32_u16(vsraq_n_u16(highBits, highBits, 7))

    # Repeat with wider lanes.
    let
      paired32 = vreinterpretq_u64_u32(vsraq_n_u32(paired16, paired16, 14))
      paired64 = vreinterpretq_u8_u64(vsraq_n_u64(paired32, paired32, 28))

    # Extract the low 8 bits from each lane and join them.
    cast[int32](vgetq_lane_u8(paired64, 0)) or
      cast[int32](vgetq_lane_u8(paired64, 8) shl 8'i32)

  template mask8NeonImpl(vec: uint8x16, against: uint8x16): int32 =
    moveMaskNeonImpl(vceqq_u8(vec, against))

  template mask16NeonImpl(vec: uint16x8, against: uint16x8): int32 =
    # TODO: This needs to be verified to be correct.
    moveMaskNeonImpl(vreinterpretq_u8_u16(vceqq_u16(vec, against)))

  template mask32NeonImpl(vec: uint32x4, against: uint32x4): int32 =
    # TODO: Same as above.
    moveMaskNeonImpl(vreinterpretq_u8_u32(vceqq_u32(vec, against)))

  template mask64NeonImpl(vec: uint64x2, against: uint64x2): int32 =
    # TODO: Sigh... same as above.
    moveMaskNeonImpl(vreinterpretq_u8_u64(vceqq_u64(vec, against)))

when hasSse2:
  template mask8Sse2Impl*(vec: M128i, against: M128i): int32 =
    mm_movemask_epi8(mm_cmpeq_epi8(vec, against))

  template mask16Sse2Impl*(vec: M128i, against: M128i): int32 =
    mm_movemask_epi8(mm_cmpeq_epi16(vec, against))

  template mask32Sse2Impl*(vec: M128i, against: M128i): int32 =
    mm_movemask_epi8(mm_cmpeq_epi32(vec, against))

  when hasSse41:
    template mask64Sse41Impl*(vec: M128i, against: M128i): int32 =
      mm_movemask_epi8(mm_cmpeq_epi64(vec, against))

  template mask64Sse2Impl*(vec: M128i, against: M128i): int32 =
    {.warning: "Using slower SSE2 based mask64() op, performance will be degraded.".}
    {.warning: "If possible, please compile with SSE4.1 support (-d:sse41)".}

    let e = mm_cmpeq_epi32(vec, against)
    mm_movemask_epi8(mm_and_si128(e, mm_shuffle_epi32(e, MM_SHUFFLE(2, 3, 0, 1))))

  template moveMaskSse2Impl(vec: M128i): int32 =
    mm_movemask_epi8(vec)

  template mask8ScalarImpl*[U: Vectorizable](vec, against: RegisterImpl[U]): int32 =
    var eqRes: RegisterImpl[U]()
    for i in 0 ..< 32:
      #!fmt: off
      eqRes[i] =
        if vec[i] == against[i]:
          cast[U](0xFF)
        else:
          cast[U](0x00)
      #!fmt: on

    var mask: int32
    for i in 0 ..< 32:
      mask = mask or cast[int32]((cast[uint8](eqRes[i]) shr 7'u8) and cast[uint8](i))

    # debugecho "mask " & $mask

    move(mask)

  template mask16ScalarImpl*[U: Vectorizable](vec, against: RegisterImpl[U]): int32 =
    0'i32

  template mask32ScalarImpl*[U: Vectorizable](vec, against: RegisterImpl[U]): int32 =
    0'i32

  template mask64ScalarImpl*[U: Vectorizable](vec, against: RegisterImpl[U]): int32 =
    0'i32

func mask*[U: Vectorizable](vec: Vector[U], against: Vector[U]): int32 {.inline.} =
  if vec.size == 1:
    # 32x uint8
    when hasAvx2:
      return mask8Avx2Impl(vec.reg, against.reg)
    elif hasSse2:
      return mask8Sse2Impl(vec.reg, against.reg)
    elif hasNeon:
      return mask8NeonImpl(vec.reg, against.reg)
  elif vec.size == 2:
    # 16x uint16
    when hasAvx2:
      return mask16Avx2Impl(vec.reg, against.reg)
    elif hasSse2:
      return mask16Sse2Impl(vec.reg, against.reg)
    elif hasNeon:
      return mask16NeonImpl(cast[uint16x8](vec.reg), cast[uint16x8](against.reg))
  elif vec.size == 4:
    # 8x uint32
    when hasAvx2:
      return mask32Avx2Impl(vec.reg, against.reg)
    elif hasSse2:
      return mask32Sse2Impl(vec.reg, against.reg)
    elif hasNeon:
      return mask32NeonImpl(cast[uint32x4](vec.reg), cast[uint32x4](against.reg))
  elif vec.size == 8:
    # 4x uint64
    when hasAvx2:
      return mask64Avx2Impl(vec.reg, against.reg)
    elif hasSse41:
      return mask64Sse41Impl(vec.reg, against.reg)
    elif hasSse2:
      return mask64Sse2Impl(vec.reg, against.reg)
    elif hasNeon:
      return mask64NeonImpl(cast[uint64x2](vec.reg), cast[uint64x2](against.reg))

func moveMask*[U: Vectorizable](vec: Vector[U]): int32 {.inline.} =
  when hasAvx2:
    moveMaskAvx2Impl(vec.reg)
  elif hasSse2:
    moveMaskSse2Impl(vec.reg)
  else:
    {.error: "Unsupported architecture for moveMask()".}

func findAllOccurrences*[U: Vectorizable](
    vec: Vector[U], against: Vector[U]
): seq[uint8] {.inline.} =
  let masked = mask(vec, against)
  var occurrences: seq[uint8]

  for i in 0'u8 ..< 32'u8:
    if ((masked shr i) and 1) == 1:
      occurrences &= i

  ensureMove(occurrences)
