This directory contains the code that generates the test vectors. The
following files are exactly the unmodified files from the NIST-provided
TestVectorGen.zip archive:

    crypto_aead.h
    crypto_hash.h
    genkat_aead.c
    genkat_hash.c

This file is a modified version of genkat_aead.c that should be used
for Saturnin-Short:

    genkat_aead_short.c


To reproduce the test vectors, first uncompress in this directory the
contents of the saturninv2.tgz archive:

    tar xvzf ../saturninv2.tgz

Here follow the specific instructions for each of Saturnin-Hash,
Saturnin-CTR-Cascade, and Saturnin-Short:


=== Saturnin-Hash

To compile and run the tests for Saturnin-Hash implementation 'xxx'
(where 'xxx' is either 'ref' or 'bs32'):

    cc -I . -I crypto_hash/saturninhashv2/xxx genkat_hash.c crypto_hash/saturninhashv2/xxx/*.c
    ./a.out

This produces the LWC_HASH_KAT_256.txt file which should be identical to
the one in crypto_hash/saturninhashv2/.


=== Saturnin-CTR-Cascade

For Saturnin-CTR-Cascade, implementation 'xxx' (which can be 'ref', 'bs32',
'bs32x' or 'bs64'):

    cc -I . -I crypto_aead/saturninctrcascadev2/xxx genkat_aead.c crypto_aead/saturninctrcascadev2/xxx/*.c
    ./a.out

Output file is LWC_AEAD_KAT_256_128.txt.


=== Saturnin-Short

For Saturnin-Short, you need to use genkat_aead_short.c instead of
genkat_aead.c, owing to the input length requirements of the specialized
mode Saturnin-Short (no additional data, plaintext length of less than
16 bytes). Only one implementation (called 'ref') is provided:

    cc -I . -I crypto_aead/saturninshortv2/ref genkat_aead_short.c crypto_aead/saturninshortv2/ref/*.c
    ./a.out

Output file is LWC_AEAD_KAT_256_128.txt.
