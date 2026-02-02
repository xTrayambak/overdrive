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

when hasNeon:
  template addVecNeonImpl[U: Vectorizable](a, b: Vector[U]): Vector[U] =
    var vec: Vector[U]
    case sizeof(U)
    of 1:
      vec.reg =
        cast[RegisterImpl[U]](vaddq_u8(cast[uint8x16](a.reg), cast[uint8x16](b.reg)))
    # uint8 (16x u8)
    of 2:
      vec.reg =
        cast[RegisterImpl[U]](vaddq_u16(cast[uint16x8](a.reg), cast[uint16x8](b.reg)))
    # uint16 (8x u16)
    of 4:
      vec.reg =
        cast[RegisterImpl[U]](vaddq_u32(cast[uint32x4](a.reg), cast[uint32x4](b.reg)))
    # uint32 (4x u32)
    of 8:
      vec.reg =
        cast[RegisterImpl[U]](vaddq_u64(cast[uint64x2](a.reg), cast[uint64x2](b.reg)))
        # uint64 (2x u64)
    else:
      discard

    ensureMove(vec)

  template subVecNeonImpl[U: Vectorizable](a, b: Vector[U]): Vector[U] =
    var vec: Vector[U]
    case sizeof(U)
    of 1:
      vec.reg =
        cast[RegisterImpl[U]](vsubq_u8(cast[uint8x16](a.reg), cast[uint8x16](b.reg)))
    # uint8 (16x u8)
    of 2:
      vec.reg =
        cast[RegisterImpl[U]](vsubq_u16(cast[uint16x8](a.reg), cast[uint16x8](b.reg)))
    # uint16 (8x u16)
    of 4:
      vec.reg =
        cast[RegisterImpl[U]](vsubq_u32(cast[uint32x4](a.reg), cast[uint32x4](b.reg)))
    # uint32 (4x u32)
    of 8:
      vec.reg =
        cast[RegisterImpl[U]](vsubq_u64(cast[uint64x2](a.reg), cast[uint64x2](b.reg)))
        # uint64 (2x u64)
    else:
      discard

    ensureMove(vec)

func `+`*[U: Vectorizable](a, b: Vector[U]): Vector[U] {.inline.} =
  when hasAvx2:
    addVecAvx2Impl(a, b)
  elif hasSse2:
    addVecSseImpl(a, b)
  elif hasNeon:
    addVecNeonImpl(a, b)
  else:
    {.error: "Unsupported architecture for `+`".}

func `-`*[U: Vectorizable](a, b: Vector[U]): Vector[U] {.inline.} =
  when hasAvx2:
    subVecAvx2Impl(a, b)
  elif hasSse2:
    subVecSseImpl(a, b)
  elif hasNeon:
    subVecNeonImpl(a, b)
  else:
    {.error: "Unsupported architecture for `-`".}
