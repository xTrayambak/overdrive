## Types for overdrive
##
## Copyright (C) 2025 Trayambak Rai (xtrayambak at disroot dot org)
import pkg/overdrive/flags

const ScalarSWRegisterSize* {.intdefine: "OverdriveScalarRegSize".} = 32

type
  Vectorizable* = SomeNumber | char | byte

  RegisterImpl*[U: Vectorizable] = (
    when hasAvx2:
      M256i
    elif hasSse2 or hasSse3 or hasSse41:
      M128i
    else:
      array[ScalarSWRegisterSize, U]
  )

  Vector*[U: Vectorizable] = object
    reg*: RegisterImpl[U]

func size*[U: Vectorizable](_: Vector[U]): int {.inline, raises: [].} =
  sizeof(U)

func capacity*[U: Vectorizable](vec: Vector[U]): int {.inline, raises: [].} =
  int(sizeof(RegisterImpl) / size(vec))
