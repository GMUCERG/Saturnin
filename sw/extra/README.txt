Sample extra implementations of Saturnin.

This directory contains a portable C implementation, and two assembly
implementations (for ARM Cortex-M3 and ARM Cortex-M4), of
Saturnin-CTR-Cascade and Saturnin-Hash. All three follow the API
described in saturnin.h. The ARM implementations assume a little-endian
processor, and follow the AAPCS call convention.

This API is not the same as the API mandated by NIST for the reference
implementation because it aims at assessing code size footprint in a
realistic context:

  - The NIST API expects the message to be processed as a single chunk
    in RAM; for AEAD, it furthermore expects the authentication tag to
    be part of that chunk. Practical implementations in constrained
    environment may not have sufficient RAM resources to follow that
    format; thus, a practical API should allow processing data in
    several chunks of arbitrary length, and give access to a separate
    authentication tag. Support for such a streamed API implies an
    increased code footprint.

  - Saturnin-CTR-Cascade and Saturnin-Hash may share some code, in
    particular the core implementation of the block cipher. The effect
    of such sharing on overall code footprint cannot be measured with
    the NIST API, since the latter keeps AEAD and hash function
    implementations as separate independent entities.

All three implementations are fully thread-safe and reentrant, since
they operate on a caller-provided context structure and use no
non-constant static data. For maximum portability, they use no external
library functions except the ubiquitous memcpy() and memset(), which are
available even in freestanding C implementations, and likely to be
already used in any application code base.

saturnin_portable.c:
    Portable, pure 32-bit C implementation.
    When compiled with GCC 7.3.0 for ARM Cortex M4, the code size is
    3956 bytes, and speed (in cycles per bytes) is the following:
      Saturnin-CTR-Cascade (additional data):  128 cpb
      Saturnin-CTR-Cascade (encrypt/decrypt):  250 cpb
      Saturnin-Hash:                           183 cpb

saturnin_m4.s:
    Assembly implementation, for ARM Cortex-M4. It is faster and smaller
    than the C code; code size is 2948 bytes, and speed is:
      Saturnin-CTR-Cascade (additional data):   75 cpb
      Saturnin-CTR-Cascade (encrypt/decrypt):  144 cpb
      Saturnin-Hash:                           111 cpb

saturnin_m3.s:
    Assembly implementation, for ARM Cortex-M3. It is very similar to
    the assembly implementation for the M4. Indeed, the M3 and M4
    implement the same ARM architecture (ARMv7-M); however, the M4
    also offers some "DSP" instructions, and saturnin_m4.s uses two
    of these instructions (pkhbt and pkhtb). The M3 does not support
    these instructions, therefore saturnin_m3.s replaces them with
    other instructions that make the code slightly larger (3028 bytes
    instead of 2948) and slower (about 2 ot 3 extra cpb).

Performance was measured on an ARM Cortex-M4F core (Nordic nRF52832
microcontroller). For all of the instructions used in the saturnin_m3.s
file, instruction timings on the M3 are supposed to be identical to
those on the M4. Therefore, the performance benchmarks above should
represent expected performance on the M3 as well.

In saturnin_m4.s, the block cipher itself and its round constants for
the different variants used in Saturnin-CTR-Cascade and Saturnin-Hash
amount to 2022 bytes of code; thus, support for the streamed API for
both the AEAD and the hash function, including the actual mode
implementation, accounts for only 926 bytes of code in total.
