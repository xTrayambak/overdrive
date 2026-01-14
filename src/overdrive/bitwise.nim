## Bitwise operations on vectors
##
## Copyright (C) 2026 Trayambak Rai (xtrayambak@disroot.org)
import pkg/overdrive/[types, flags]
import pkg/shakar

when hasAvx2:
  template allZeroAvx2Impl[U: Vectorizable](a, b: Vector[U]): bool =
    mm256_testz_si256(a.reg, b.reg) == 0'i32

when hasSse41:
  template allZeroSse41Impl[U: Vectorizable](a, b: Vector[U]): bool =
    mm_testz_si128(a.reg, b.reg) == 0'i32

when hasSse2:
  template allZeroSse2Impl[U: Vectorizable](a, b: Vector[U]): bool =
    {.warning: "Using slower SSE2 based allZero() op, performance will be degraded.".}
    {.warning: "If possible, please compile with SSE 4.1 support (-d:sse41)".}

    let x = mm_and_si128(a.reg, b.reg)
    var t = mm_or_si128(x, mm_srli_si128(x, 8))

    t = mm_or_si128(t, mm_srli_si128(t, 4))

    return mm_cvtsi12_si32(t) == 0'i32

func allZero*[U: Vectorizable](a, b: Vector[U]): bool =
  when hasAvx2:
    allZeroAvx2Impl(a, b)
  elif hasSse41:
    allZeroSse41Impl(a, b)
  elif hasSse2:
    allZeroSse2Impl(a, b)
  else:
    {.error: "Unsupported architecture for allZero()".}
