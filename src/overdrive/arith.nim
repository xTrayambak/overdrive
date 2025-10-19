## Accelerated arithmetic operations
##
## Copyright (C) 2025 Trayambak Rai (xtrayambak at disroot dot org)
import pkg/overdrive/[flags, types]
import pkg/shakar

template addVecAvx2Impl[U: Vectorizable](a, b: Vector[U]): Vector[U] =
  var vec: Vector[U]
  case a.size
  of 1:
    # uint8 (32x u8)
    vec.reg = mm256_add_epi8(a.reg, b.reg)
  of 2:
    # uint16 (16x u16)
    vec.reg = mm256_add_epi16(a.reg, b.reg)
  of 4:
    # uint32 (8x u32)
    vec.reg = mm256_add_epi32(a.reg, b.reg)
  of 8:
    # uint64 (4x u64)
    vec.reg = mm256_add_epi64(a.reg, b.reg)
  else:
    unreachable

  ensureMove(vec)

template addVecSseImpl[U: Vectorizable](a, b: Vector[U]): Vector[U] =
  var vec: Vector[U]
  case vec.size
  of 1:
    # uint8 (32x u8)
    vec.reg = mm_add_epi8(a.reg, b.reg)
  of 2:
    # uint16 (16x u16)
    vec.reg = mm_add_epi16(a.reg, b.reg)
  of 4:
    # uint32 (8x u32)
    vec.reg = mm_add_epi32(a.reg, b.reg)
  of 8:
    # uint64 (4x u64)
    vec.reg = mm_add_epi64(a.reg, b.reg)
  else:
    unreachable

  ensureMove(vec)

func addImpl[U: Vectorizable](a, b: Vector[U]): Vector[U] {.inline.} =
  when hasAvx2:
    addVecAvx2Impl(a, b)
  elif hasSse2:
    addVecSseImpl(a, b)
  else:
    unreachable

func `+`*[U: Vectorizable](a, b: Vector[U]): Vector[U] {.inline.} =
  addImpl(a, b)
