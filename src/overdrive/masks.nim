## Masking routines
##
## Copyright (C) 2025 Trayambak Rai (xtrayambak at disroot dot org)
import pkg/overdrive/[flags, types]

when hasAvx2:
  template mask8*(vec: M256i, against: M256i): int32 =
    mm256_movemask_epi8(mm256_cmpeq_epi8(vec, against))

  template mask16*(vec: M256i, against: M256i): int32 =
    mm256_movemask_epi8(mm256_cmpeq_epi16(vec, against))

  template mask32*(vec: M256i, against: M256i): int32 =
    mm256_movemask_epi8(mm256_cmpeq_epi32(vec, against))

  template mask64*(vec: M256i, against: M256i): int32 =
    mm256_movemask_epi8(mm256_cmpeq_epi64(vec, against))

  template moveMaskAvx2Impl*(vec: M256i): int32 =
    mm256_movemask_epi8(vec)

else:
  when hasSse2:
    template mask8*(vec: M128i, against: M128i): int32 =
      mm_movemask_epi8(mm_cmpeq_epi8(vec, against))

    template mask16*(vec: M128i, against: M128i): int32 =
      mm_movemask_epi8(mm_cmpeq_epi16(vec, against))

    template mask32*(vec: M128i, against: M128i): int32 =
      mm_movemask_epi8(mm_cmpeq_epi32(vec, against))

    when hasSse41:
      template mask64*(vec: M128i, against: M128i): int32 =
        mm_movemask_epi8(mm_cmpeq_epi64(vec, against))

    else:
      template mask64*(vec: M128i, against: M128i): int32 =
        {.
          warning: "Using slower SSE2 based mask64() op, performance will be degraded."
        .}
        {.warning: "If possible, please compile with SSE4.1 support (-d:sse41)".}

        let e = mm_cmpeq_epi32(vec, against)
        mm_movemask_epi8(mm_and_si128(e, mm_shuffle_epi32(e, MM_SHUFFLE(2, 3, 0, 1))))

    template moveMaskSse2Impl(vec: M128i): int32 =
      mm_movemask_epi8(vec)

  else:
    template mask8*[U: Vectorizable](vec, against: RegisterImpl[U]): int32 =
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

    template mask16*[U: Vectorizable](vec, against: RegisterImpl[U]): int32 =
      0'i32

    template mask32*[U: Vectorizable](vec, against: RegisterImpl[U]): int32 =
      0'i32

    template mask64*[U: Vectorizable](vec, against: RegisterImpl[U]): int32 =
      0'i32

func mask*[U: Vectorizable](vec: Vector[U], against: Vector[U]): int32 {.inline.} =
  if vec.size == 1:
    # 32x uint8
    return mask8(vec.reg, against.reg)
  elif vec.size == 2:
    # 16x uint16
    return mask16(vec.reg, against.reg)
  elif vec.size == 4:
    # 8x uint32
    return mask32(vec.reg, against.reg)
  elif vec.size == 8:
    # 4x uint64
    return mask64(vec.reg, against.reg)

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
