## Equality routines
##
## Copyright (C) 2026 Trayambak Rai (xtrayambak@disroot.org)
import pkg/overdrive/[flags, types]

when hasSse2:
  template equalSse2Impl[U: Vectorizable](a, b: Vector[U]): M128i =
    when U is uint8 or U is int8 or U is char:
      mm_cmpeq_epi8(a.reg, b.reg)
    elif U is uint16 or U is int16:
      mm_cmpeq_epi16(a.reg, b.reg)
    elif U is uint32 or U is int32:
      mm_cmpeq_epi32(a.reg, b.reg)
    elif U is uint64 or U is int64:
      mm_cmpeq_epi64(a.reg, b.reg)
    else:
      {.error: "Unsupported type for vector: " & $U.}

when hasAvx2:
  template equalAvx2Impl[U: Vectorizable](a, b: Vector[U]): M256i =
    when U is uint8 or U is int8 or U is char:
      mm256_cmpeq_epi8(a.reg, b.reg)
    elif U is uint16 or U is int16:
      mm256_cmpeq_epi16(a.reg, b.reg)
    elif U is uint32 or U is int32:
      mm256_cmpeq_epi32(a.reg, b.reg)
    elif U is uint64 or U is int64:
      mm256_cmpeq_epi64(a.reg, b.reg)
    else:
      {.error: "Unsupported type for vector: " & $U.}

when hasNeon:
  template equalNeonImpl[U: Vectorizable](a, b: Vector[U]): RegisterImpl[U] =
    when U is uint8 or U is int8 or U is char:
      vceqq_u8(a.reg, b.reg)
    elif U is uint16 or U is int16:
      vceqq_u16(a.reg, b.reg)
    elif U is uint32 or U is int32:
      vceqq_u32(a.reg, b.reg)
    elif U is uint64 or U is int64:
      vceqq_u64(a.reg, b.reg)
    else:
      {.error: "Unsupported type for vector: " & $U.}

template `==`*[U: Vectorizable](a, b: Vector[U]): Vector[U] =
  when hasAvx2:
    Vector[U](reg: equalAvx2Impl(a, b))
  elif hasSse2:
    Vector[U](reg: equalSse2Impl(a, b))
  elif hasNeon:
    Vector[U](reg: equalNeonImpl(a, b))
