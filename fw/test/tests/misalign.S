# See LICENSE for license details.

#*****************************************************************************
# misalign.S
#-----------------------------------------------------------------------------
#
# Test misalignment detection and handling
#

#include "riscv_test.h"
#include "test_macros.h"

.global misalign_sw_1
.global misalign_sw_2
.global misalign_sw_3
.global misalign_sh_1
.global misalign_sh_3
.global misalign_lw_1
.global misalign_lw_2
.global misalign_lw_3
.global misalign_lh_1
.global misalign_lh_3
.global aligned_word

RVTEST_RV32U
RVTEST_CODE_BEGIN

  # prepare data word address in t0
  lui t0, %hi(aligned_word)
  addi t0, t0, %lo(aligned_word)

  # prepare dummy data in t1
  lui t1, %hi(0x12345678)
  addi t1, t1, %lo(0x12345678)

  ###############################
  # MISALIGNED SW

  # successful write
  TEST_CASE(2, t2, 0x12345678,  \
    addi t2, zero, 0;           \
    sw t1, 0(t0);               \
    lw t2, 0(t0);               \
  )

  # trap
  TEST_CASE(3, t2, 0x12345678,  \
    addi t2, zero, 0;           \
misalign_sw_1:                  \
    sw t1, 1(t0);               \
    lw t2, 0(t0);               \
  )

  # trap
  TEST_CASE(4, t2, 0x12345678,  \
    addi t2, zero, 0;           \
misalign_sw_2:                  \
    sw t1, 2(t0);               \
    lw t2, 0(t0);               \
  )

  # trap
  TEST_CASE(5, t2, 0x12345678,  \
    addi t2, zero, 0;           \
misalign_sw_3:                  \
    sw t1, 3(t0);               \
    lw t2, 0(t0);               \
  )

  # success
  TEST_CASE(6, t2, 0x12345678,  \
    addi t2, zero, 0;           \
    sw t1, 4(t0);               \
    lw t2, 0(t0);               \
  )

  ###############################
  # MISALIGNED SH

  # success
  TEST_CASE(7, t2, 0x12345678,  \
    addi t2, zero, 0;           \
    sh t1, 0(t0);               \
    lw t2, 0(t0);               \
  )

  # trap
  TEST_CASE(8, t2, 0x12345678,  \
    addi t2, zero, 0;           \
misalign_sh_1:
    sh t1, 1(t0);               \
    lw t2, 0(t0);               \
  )

  # success
  TEST_CASE(9, t2, 0x56785678, \
    addi t2, zero, 0;           \
    sh t1, 2(t0);               \
    lw t2, 0(t0);               \
  )

  # trap
  TEST_CASE(10, t2, 0x56785678, \
    addi t2, zero, 0;           \
misalign_sh_3:
    sh t1, 3(t0);               \
    lw t2, 0(t0);               \
  )

  # success
  TEST_CASE(11, t2, 0x56785678, \
    addi t2, zero, 0;           \
    sh t1, 4(t0);               \
    lw t2, 0(t0);               \
  )

  ###############################
  # MISALIGNED LW

  # success
  TEST_CASE(12, t2, 0x56785678,  \
    addi t2, zero, 0;           \
    lw t2, 0(t0);               \
  )

  # trap
  TEST_CASE(13, t2, 0,          \
    addi t2, zero, 0;           \
misalign_lw_1:
    lw t2, 1(t0);               \
  )

  # trap
  TEST_CASE(14, t2, 0,          \
    addi t2, zero, 0;           \
misalign_lw_2:
    lw t2, 2(t0);               \
  )

  # trap
  TEST_CASE(15, t2, 0,          \
    addi t2, zero, 0;           \
misalign_lw_3:
    lw t2, 3(t0);               \
  )

  # success
  TEST_CASE(16, t2, 0x12345678, \
    addi t2, zero, 0;           \
    lw t2, 4(t0);               \
  )

  ###############################
  # MISALIGNED LH

  # success
  TEST_CASE(17, t2, 0x5678,     \
    addi t2, zero, 0;           \
    lh t2, 0(t0);               \
  )

  # trap
  TEST_CASE(18, t2, 0,          \
    addi t2, zero, 0;           \
misalign_lh_1:
    lh t2, 1(t0);               \
  )

  # success
  TEST_CASE(19, t2, 0x5678,     \
    addi t2, zero, 0;           \
    lh t2, 2(t0);               \
  )

  # trap
  TEST_CASE(20, t2, 0,          \
    addi t2, zero, 0;           \
misalign_lh_3:
    lh t2, 3(t0);               \
  )

  # success
  TEST_CASE(21, t2, 0x5678,     \
    addi t2, zero, 0;           \
    lh t2, 4(t0);               \
  )

  TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

aligned_word:
  .fill 2, 4

RVTEST_DATA_END
