## Accelerated arithmetic operations
##
## Copyright (C) 2025-2026 Trayambak Rai (xtrayambak at disroot dot org)
import pkg/overdrive/[flags, types]
import pkg/shakar

when hasAvx2:
  template addVecAvx2Impl[U: Vectorizable](a, b: Vector[U]): Vector[U] =
    Vector[U](
      reg:
        case a.size
        of 1:
          # uint8 (32x u8)
          mm256_add_epi8(a.reg, b.reg)
        of 2:
          # uint16 (16x u16)
          mm256_add_epi16(a.reg, b.reg)
        of 4:
          # uint32 (8x u32)
          mm256_add_epi32(a.reg, b.reg)
        of 8:
          # uint64 (4x u64)
          mm256_add_epi64(a.reg, b.reg)
        else:
          unreachable
          M256i()
    )

  template subVecAvx2Impl[U: Vectorizable](a, b: Vector[U]): Vector[U] =
    Vector[U](
      reg:
        case a.size
        of 1:
          # uint8 (32x u8)
          mm256_sub_epi8(a.reg, b.reg)
        of 2:
          # uint16 (16x u16)
          mm256_sub_epi16(a.reg, b.reg)
        of 4:
          # uint32 (8x u32)
          mm256_sub_epi32(a.reg, b.reg)
        of 8:
          # uint64 (4x u64)
          mm256_sub_epi64(a.reg, b.reg)
        else:
          unreachable
          M256i()
    )

when hasSse2:
  template addVecSseImpl[U: Vectorizable](a, b: Vector[U]): Vector[U] =
    Vector[U](
      reg:
        case a.size
        of 1:
          # uint8 (16x u8)
          mm_add_epi8(a.reg, b.reg)
        of 2:
          # uint16 (8x u16)
          mm_add_epi16(a.reg, b.reg)
        of 4:
          # uint32 (4x u32)
          mm_add_epi32(a.reg, b.reg)
        of 8:
          # uint64 (2x u64)
          mm_add_epi64(a.reg, b.reg)
        else:
          unreachable
          M128i()
    )

  template subVecSseImpl[U: Vectorizable](a, b: Vector[U]): Vector[U] =
    Vector[U](
      reg:
        case a.size
        of 1:
          # uint8 (16x u8)
          mm_sub_epi8(a.reg, b.reg)
        of 2:
          # uint16 (8x u16)
          mm_sub_epi16(a.reg, b.reg)
        of 4:
          # uint32 (4x u32)
          mm_sub_epi32(a.reg, b.reg)
        of 8:
          # uint64 (2x u32)
          mm_sub_epi64(a.reg, b.reg)
        else:
          unreachable
          M128i()
    )

func `+`*[U: Vectorizable](a, b: Vector[U]): Vector[U] {.inline.} =
  when hasAvx2:
    addVecAvx2Impl(a, b)
  elif hasSse2:
    addVecSseImpl(a, b)
  else:
    {.error: "Unsupported architecture for `+`".}

func `-`*[U: Vectorizable](a, b: Vector[U]): Vector[U] {.inline.} =
  when hasAvx2:
    subVecAvx2Impl(a, b)
  elif hasSse2:
    subVecSseImpl(a, b)
  else:
    {.error: "Unsupported architecture for `-`".}
