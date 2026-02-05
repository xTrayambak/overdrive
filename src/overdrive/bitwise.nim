## Bitwise operations on vectors
##
## Copyright (C) 2026 Trayambak Rai (xtrayambak@disroot.org)
import pkg/overdrive/[types, flags]

when hasAvx2:
  template allZeroAvx2Impl[U: Vectorizable](a, b: Vector[U]): bool =
    mm256_testz_si256(a.reg, b.reg) != 0'i32

  template andAvx2Impl[U: Vectorizable](a, b: Vector[U]): Vector[U] =
    Vector[U](reg: mm256_and_si256(a.reg, b.reg))

  template orAvx2Impl[U: Vectorizable](a, b: Vector[U]): Vector[U] =
    Vector[U](reg: mm256_or_si256(a.reg, b.reg))

when hasSse41:
  template allZeroSse41Impl[U: Vectorizable](a, b: Vector[U]): bool =
    mm_testz_si128(a.reg, b.reg) != 0'i32

when hasSse2:
  template allZeroSse2Impl[U: Vectorizable](a, b: Vector[U]): bool =
    {.warning: "Using slower SSE2 based allZero() op, performance will be degraded.".}
    {.warning: "If possible, please compile with SSE 4.1 support (-d:sse41)".}

    mm_movemask_epi8(mm_cmpeq_epi8(mm_and_si128(a.reg, b.reg), mm_setzero_si128())) ==
      0xFFFF'i32

  template andSse2Impl[U: Vectorizable](a, b: Vector[U]): Vector[U] =
    Vector[U](reg: mm_and_si128(a.reg, b.reg))

  template orSse2Impl[U: Vectorizable](a, b: Vector[U]): Vector[U] =
    Vector[U](reg: mm_or_si128(a.reg, b.reg))

when hasNeon:
  template allZeroNeonImpl[U: Vectorizable](a, b: Vector[U]): bool =
    vmaxvq_u8(vandq_u8(a.reg, b.reg)) == 0'u8

func allZero*[U: Vectorizable](a, b: Vector[U]): bool =
  when hasAvx2:
    allZeroAvx2Impl(a, b)
  elif hasSse41:
    allZeroSse41Impl(a, b)
  elif hasSse2:
    allZeroSse2Impl(a, b)
  elif hasNeon:
    allZeroNeonImpl(a, b)
  else:
    {.error: "Unsupported architecture for allZero()".}

func `and`*[U: Vectorizable](a, b: Vector[U]): Vector[U] =
  when hasAvx2:
    andAvx2Impl(a, b)
  elif hasSse2:
    andSse2Impl(a, b)
  else:
    {.error: "Unsupported architecture for `and`".}

func `or`*[U: Vectorizable](a, b: Vector[U]): Vector[U] =
  when hasAvx2:
    orAvx2Impl(a, b)
  elif hasSse2:
    orSse2Impl(a, b)
  else:
    {.error: "Unsupported architecture for `or`".}
