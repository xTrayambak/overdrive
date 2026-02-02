## Compile-time vectorization detection
## Also exports the needed routines
##
## Copyright (C) 2025 Trayambak Rai (xtrayambak at disroot dot org)

type VInstSet* {.pure, size: sizeof(uint8).} = enum
  AVX2
  SSE2
  SSE3
  SSE4_1
  NEON
  Scalar

const InstSet* =
  when defined(aarch64):
    VInstSet.NEON
  elif defined(amd64):
    when defined(avx2):
      VInstSet.AVX2
    elif defined(sse3):
      VInstSet.SSE3
    elif defined(sse2):
      VInstSet.SSE2
    elif defined(sse41) or true:
      # The vast majority of desktop x64 CPUs now
      # support SSE4.1, so we can safely use that
      # as a baseline. If you wish to compile a
      # program for an older system, explicitly
      # compile it with `-d:sse3` or even `-d:sse2`
      VInstSet.SSE4_1
  else:
    VInstSet.Scalar

func `$`(inst: VInstSet): string {.raises: [], compileTime.} =
  case inst
  of VInstSet.Scalar: "Scalar"
  of VInstSet.AVX2: "AVX2"
  of VInstSet.SSE3: "SSE3"
  of VInstSet.SSE2: "SSE2"
  of VInstSet.SSE4_1: "SSE4.1"
  of VInstSet.NEON: "NEON"

func getBackend*(): VInstSet {.inline, compileTime, raises: [].} =
  InstSet

static:
  when InstSet != VInstSet.Scalar:
    {.hint: "overdrive is using the " & $InstSet & " instruction set".}

const
  hasAvx2* = InstSet == VInstSet.AVX2
  hasSse41* = InstSet == VInstSet.SSE4_1
  hasSse3* = hasSse41 or InstSet == VInstSet.SSE3
  hasSse2* = hasSse3 or InstSet == VInstSet.SSE2
  hasNeon* = InstSet == VInstSet.NEON

  passCompilerSupportFlags =
    not defined(overdriveDontPassCompilerFlags) and (defined(gcc) or defined(clang))

when hasAvx2:
  when passCompilerSupportFlags:
    {.passC: "-mavx2".}

  import pkg/nimsimd/avx2
  export avx2
elif hasSse41:
  when passCompilerSupportFlags:
    {.passC: "-msse4.1".}

  import pkg/nimsimd/[sse2, sse3, sse41]
  export sse2, sse3, sse41
elif hasSse3:
  when passCompilerSupportFlags:
    {.passC: "-msse3".}

  import pkg/nimsimd/[sse2, sse3]
  export sse2, sse3
elif hasSse2:
  when passCompilerSupportFlags:
    {.passC: "-msse2".}

  import pkg/nimsimd/sse2
  export sse2
elif hasNeon:
  import pkg/nimsimd/neon
  export neon
else:
  discard "Nothing is required to be imported."
