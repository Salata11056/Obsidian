# Copyright 2025 Mattia Giambirtone & All Contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# SIMD routines to speed up NNUE inference

when defined(avx512):
    {.localPassC:"-mavx512f -mavx512bw".}

    import heimdall/util/avx/avx512_intrin

    type
        VEPI16* = M512i
        VEPI32* = M512i

    const CHUNK_SIZE* = 32

    # Routines blatantly stolen from Alexandria. Many thanks cj!
    func vecZero16*: VEPI16 {.inline.} = mm512_setzero_si512()
    func vecZero32*: VEPI32 {.inline.} = mm512_setzero_si512()
    func vecSetOne16*(n: int16): VEPI16 {.inline.} = mm512_set1_epi16(n)
    func vecStore*(dst: pointer, vec: VEPI16) = mm512_store_si512(dst, vec)
    func vecLoad*(src: pointer): VEPI16 {.inline.} = mm512_load_si512(src)
    func vecMax16*(vec0, vec1: VEPI16): VEPI16 {.inline.} = mm512_max_epi16(vec0, vec1)
    func vecMin16*(vec0, vec1: VEPI16): VEPI16 {.inline.} = mm512_min_epi16(vec0, vec1)
    func vecMullo16*(vec0, vec1: VEPI16): VEPI16 {.inline.} = mm512_mullo_epi16(vec0, vec1)
    func vecMadd16*(vec0, vec1: VEPI16): VEPI32 {.inline.} = mm512_madd_epi16(vec0, vec1)
    func vecAdd16*(vec0, vec1: VEPI16): VEPI16 {.inline.} = mm512_add_epi16(vec0, vec1)
    func vecAdd32*(vec0, vec1: VEPI32): VEPI32 {.inline.} = mm512_add_epi32(vec0, vec1)
    func vecSub16*(vec0, vec1: VEPI16): VEPI16 {.inline.} = mm512_sub_epi16(vec0, vec1)
    func vecReduceAdd32*(vec: VEPI32): int32 {.inline.} = mm512_reduce_add_epi32(vec)
else:
    when defined(avx2):
        {.localPassC:"-mavx2".}

        import nimsimd/avx2

        type
            VEPI16* = M256i
            VEPI32* = M256i

        const CHUNK_SIZE* = 16

        # Routines blatantly stolen from Alexandria. Many thanks cj!
        func vecZero16*: VEPI16 {.inline.} = mm256_setzero_si256()
        func vecZero32*: VEPI32 {.inline.} = mm256_setzero_si256()
        func vecSetOne16*(n: int16): VEPI16 {.inline.} = mm256_set1_epi16(n)
        func vecStore*(dst: pointer, vec: VEPI16) = mm256_store_si256(dst, vec)
        func vecLoad*(src: pointer): VEPI16 {.inline.} = mm256_load_si256(src)
        func vecMax16*(vec0, vec1: VEPI16): VEPI16 {.inline.} = mm256_max_epi16(vec0, vec1)
        func vecMin16*(vec0, vec1: VEPI16): VEPI16 {.inline.} = mm256_min_epi16(vec0, vec1)
        func vecMullo16*(vec0, vec1: VEPI16): VEPI16 {.inline.} = mm256_mullo_epi16(vec0, vec1)
        func vecMadd16*(vec0, vec1: VEPI16): VEPI32 {.inline.} = mm256_madd_epi16(vec0, vec1)
        func vecAdd32*(vec0, vec1: VEPI32): VEPI32 {.inline.} = mm256_add_epi32(vec0, vec1)
        func vecAdd16*(vec0, vec1: VEPI16): VEPI16 {.inline.} = mm256_add_epi16(vec0, vec1)
        func vecSub16*(vec0, vec1: VEPI16): VEPI16 {.inline.} = mm256_sub_epi16(vec0, vec1)
        # AVX2 doesn't have an intrinsic for vec_reduce_add_epi32 (AVX512 does), but thankfully
        # cj wrote the implementation for us!
        func vecReduceAdd32*(vec: VEPI32): int32 {.inline.} =
            var
                lo128 = mm256_castsi256_si128(vec)
                hi128 = mm256_extracti128_si256(vec, 1)
                sum128 = mm_add_epi32(lo128, hi128)

                hi64 = mm_unpackhi_epi64(sum128, sum128)
                sum64 = mm_add_epi32(hi64, sum128)

                hi32 = mm_shuffle_epi32(sum64, 1)
                sum32 = mm_add_epi32(hi32, sum64)

            result = mm_cvtsi128_si32(sum32)
    else:
        let CHUNK_SIZE* = 1
