## Store ops for overdrive
##
## Copyright (C) 2025-2026 Trayambak Rai (xtrayambak at disroot dot org)
import pkg/overdrive/[types, flags]
import pkg/shakar

{.push checks: off.}
when hasAvx2:
  template storeContainerAvx2Impl[U: Vectorizable](
      vec: var Vector[U], src: openArray[U]
  ): int =
    vec.reg = mm256_loadu_si256(cast[ptr M256i](src[0].addr))

    if src.len > vec.capacity:
      src.len - vec.capacity
    else:
      0

  template storePtrAvx2Impl[U: Vectorizable](vec: var Vector[U], src: ptr U) =
    vec.reg = mm256_loadu_si256(cast[ptr M256i](src))

  template storeOneAvx2Impl[U: Vectorizable](vec: var Vector[U], src: U) =
    when U is uint8 or U is int8 or U is char:
      # 32x u8
      vec.reg = mm256_set1_epi8(src)
    elif U is uint16 or U is int16:
      # 16x u16
      vec.reg = mm256_set1_epi16(src)
    elif U is uint32 or U is int32:
      # 8x u32
      vec.reg = mm256_set1_epi32(src)
    elif U is uint64 or U is int64:
      # 4x u16
      vec.reg = mm256_set1_epi64x(src)
    else:
      unreachable

template storeContainerScalarImpl[U: Vectorizable](
    vec: var Vector[U], src: openArray[U]
): int =
  # Quickly copy the buffer of vectorizable units
  # into our software/scalar pseudo-register

  if src.len <= ScalarSWRegisterSize:
    copyMem(vec.reg[0].addr, src[0].addr, ScalarSWRegisterSize - src.len)
    0
  else:
    copyMem(vec.reg[0].addr, src[0].addr, ScalarSWRegisterSize)
    src.len - ScalarSWRegisterSize

template storeOneScalarImpl[U: Vectorizable](vec: var Vector[U], src: U) =
  var i = 0
  while i < ScalarSWRegisterSize:
    vec.reg[i] = src
    inc i

template storePtrScalarImpl[U: Vectorizable](vec: var Vector[U], src: ptr U) =
  for i in 0 ..< 32:
    vec.reg[i] = cast[U](src[])

when hasSse2:
  template storePtrSseImpl[U: Vectorizable](vec: var Vector[U], src: ptr U) =
    vec.reg = mm_loadu_si128(cast[ptr M128i](src))

  template storeContainerSseImpl[U: Vectorizable](
      vec: var Vector[U], src: openArray[U]
  ) =
    vec.reg = mm_loadu_si128(cast[ptr M128i](src[0].addr))

    if src.len > vec.capacity:
      return src.len - vec.capacity
    else:
      return 0

  template storeOneSseImpl[U: Vectorizable](vec: var Vector[U], src: U) =
    when U is uint8 or U is int8 or U is char:
      vec.reg = mm_set1_epi8(src)
    elif U is uint16 or U is int16:
      vec.reg = mm_set1_epi16(src)
    elif U is uint32 or U is int32:
      vec.reg = mm_set1_epi32(src)
    elif U is uint64 or U is int64:
      vec.reg = mm_set1_epi64x(src)
    else:
      unreachable

func store*[U: Vectorizable](
    vec: var Vector[U], src: openArray[U]
): int {.discardable.} =
  when hasAvx2:
    storeContainerAvx2Impl(vec, src)
  elif hasSse2:
    storeContainerSseImpl(vec, src)
  else:
    storeContainerScalarImpl(vec, src)

func store*[U: Vectorizable](vec: var Vector[U], src: ptr U) {.discardable.} =
  when hasAvx2:
    storePtrAvx2Impl(vec, src)
  elif hasSse2:
    storePtrSseImpl(vec, src)
  else:
    storePtrScalarImpl(vec, src)

func store*[U: Vectorizable](vec: var Vector[U], src: U) =
  when hasAvx2:
    storeOneAvx2Impl(vec, src)
  elif hasSse2:
    storeOneSseImpl(vec, src)
  else:
    storeOneScalarImpl(vec, src)

{.pop.}
