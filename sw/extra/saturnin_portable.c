/*
 * Combined Saturnin-CTR-Cascade and Saturnin-Hash implementation, in
 * "portable C" (uses only 32-bit types). This implements the API
 * described in saturnin.h.
 */

#include <stddef.h>
#include <stdint.h>
#include <string.h>

#include "saturnin.h"

/* ======================================================================== */
/*
 * Saturnin block cipher implementation (bitslice, 32-bit registers).
 */

/*
 * We represent the sixteen 16-bit registers r0..r15 into eight 32-bit
 * variables q0..q7:
 *
 *   q0 = r0 | (r8 << 16)
 *   q1 = r1 | (r9 << 16)
 *   ...
 *   q7 = r7 | (r15 << 16)
 *
 * This is done so because S-box for r0..r3 and r8..r11 is the same;
 * similarly for S-box for r4..r7 and r12..r15.
 */

#define DECL_STATE   \
	uint32_t q0, q1, q2, q3, q4, q5, q6, q7;

#define DEC256(b, src)   do { \
		b ## 0 = (uint32_t)(src)[ 0] \
			| ((uint32_t)(src)[ 1] << 8) \
			| ((uint32_t)(src)[16] << 16) \
			| ((uint32_t)(src)[17] << 24); \
		b ## 1 = (uint32_t)(src)[ 2] \
			| ((uint32_t)(src)[ 3] << 8) \
			| ((uint32_t)(src)[18] << 16) \
			| ((uint32_t)(src)[19] << 24); \
		b ## 2 = (uint32_t)(src)[ 4] \
			| ((uint32_t)(src)[ 5] << 8) \
			| ((uint32_t)(src)[20] << 16) \
			| ((uint32_t)(src)[21] << 24); \
		b ## 3 = (uint32_t)(src)[ 6] \
			| ((uint32_t)(src)[ 7] << 8) \
			| ((uint32_t)(src)[22] << 16) \
			| ((uint32_t)(src)[23] << 24); \
		b ## 4 = (uint32_t)(src)[ 8] \
			| ((uint32_t)(src)[ 9] << 8) \
			| ((uint32_t)(src)[24] << 16) \
			| ((uint32_t)(src)[25] << 24); \
		b ## 5 = (uint32_t)(src)[10] \
			| ((uint32_t)(src)[11] << 8) \
			| ((uint32_t)(src)[26] << 16) \
			| ((uint32_t)(src)[27] << 24); \
		b ## 6 = (uint32_t)(src)[12] \
			| ((uint32_t)(src)[13] << 8) \
			| ((uint32_t)(src)[28] << 16) \
			| ((uint32_t)(src)[29] << 24); \
		b ## 7 = (uint32_t)(src)[14] \
			| ((uint32_t)(src)[15] << 8) \
			| ((uint32_t)(src)[30] << 16) \
			| ((uint32_t)(src)[31] << 24); \
	} while (0)

#define ENC256(b, dst)   do { \
		(dst)[ 0] = (uint8_t)b ## 0; \
		(dst)[ 1] = (uint8_t)(b ## 0 >> 8); \
		(dst)[16] = (uint8_t)(b ## 0 >> 16); \
		(dst)[17] = (uint8_t)(b ## 0 >> 24); \
		(dst)[ 2] = (uint8_t)b ## 1; \
		(dst)[ 3] = (uint8_t)(b ## 1 >> 8); \
		(dst)[18] = (uint8_t)(b ## 1 >> 16); \
		(dst)[19] = (uint8_t)(b ## 1 >> 24); \
		(dst)[ 4] = (uint8_t)b ## 2; \
		(dst)[ 5] = (uint8_t)(b ## 2 >> 8); \
		(dst)[20] = (uint8_t)(b ## 2 >> 16); \
		(dst)[21] = (uint8_t)(b ## 2 >> 24); \
		(dst)[ 6] = (uint8_t)b ## 3; \
		(dst)[ 7] = (uint8_t)(b ## 3 >> 8); \
		(dst)[22] = (uint8_t)(b ## 3 >> 16); \
		(dst)[23] = (uint8_t)(b ## 3 >> 24); \
		(dst)[ 8] = (uint8_t)b ## 4; \
		(dst)[ 9] = (uint8_t)(b ## 4 >> 8); \
		(dst)[24] = (uint8_t)(b ## 4 >> 16); \
		(dst)[25] = (uint8_t)(b ## 4 >> 24); \
		(dst)[10] = (uint8_t)b ## 5; \
		(dst)[11] = (uint8_t)(b ## 5 >> 8); \
		(dst)[26] = (uint8_t)(b ## 5 >> 16); \
		(dst)[27] = (uint8_t)(b ## 5 >> 24); \
		(dst)[12] = (uint8_t)b ## 6; \
		(dst)[13] = (uint8_t)(b ## 6 >> 8); \
		(dst)[28] = (uint8_t)(b ## 6 >> 16); \
		(dst)[29] = (uint8_t)(b ## 6 >> 24); \
		(dst)[14] = (uint8_t)b ## 7; \
		(dst)[15] = (uint8_t)(b ## 7 >> 8); \
		(dst)[30] = (uint8_t)(b ## 7 >> 16); \
		(dst)[31] = (uint8_t)(b ## 7 >> 24); \
	} while (0)

#define SBOX   do { \
		uint32_t a, b, c, d; \
		a = q0; \
		b = q1; \
		c = q2; \
		d = q3; \
		a ^= b & c; \
		b ^= a | d; \
		d ^= b | c; \
		c ^= b & d; \
		b ^= a | c; \
		a ^= b | d; \
		q0 = b; \
		q1 = c; \
		q2 = d; \
		q3 = a; \
		a = q4; \
		b = q5; \
		c = q6; \
		d = q7; \
		a ^= b & c; \
		b ^= a | d; \
		d ^= b | c; \
		c ^= b & d; \
		b ^= a | c; \
		a ^= b | d; \
		q4 = d; \
		q5 = b; \
		q6 = a; \
		q7 = c; \
	} while (0)

#define SBOX_INV   do { \
		uint32_t a, b, c, d; \
		b = q0; \
		c = q1; \
		d = q2; \
		a = q3; \
		a ^= b | d; \
		b ^= a | c; \
		c ^= b & d; \
		d ^= b | c; \
		b ^= a | d; \
		a ^= b & c; \
		q0 = a; \
		q1 = b; \
		q2 = c; \
		q3 = d; \
		d = q4; \
		b = q5; \
		a = q6; \
		c = q7; \
		a ^= b | d; \
		b ^= a | c; \
		c ^= b & d; \
		d ^= b | c; \
		b ^= a | d; \
		a ^= b & c; \
		q4 = a; \
		q5 = b; \
		q6 = c; \
		q7 = d; \
	} while (0)

#define MUL(t0, t1, t2, t3)   do { \
		uint32_t mul_tmp = (t0); \
		(t0) = (t1); \
		(t1) = (t2); \
		(t2) = (t3); \
		(t3) = mul_tmp ^ (t0); \
	} while (0)

#define MUL_INV(t0, t1, t2, t3)   do { \
		uint32_t mul_tmp = (t3); \
		(t3) = (t2); \
		(t2) = (t1); \
		(t1) = (t0); \
		(t0) = mul_tmp ^ (t1); \
	} while (0)

#define SW(x)   (((x) >> 16) | ((x) << 16))

#define MDS   do { \
		q0 ^= q4; q1 ^= q5; q2 ^= q6; q3 ^= q7; \
		MUL(q4, q5, q6, q7); \
		q4 ^= SW(q0); q5 ^= SW(q1); q6 ^= SW(q2); q7 ^= SW(q3); \
		MUL(q0, q1, q2, q3); \
		MUL(q0, q1, q2, q3); \
		q0 ^= q4; q1 ^= q5; q2 ^= q6; q3 ^= q7; \
		q4 ^= SW(q0); q5 ^= SW(q1); q6 ^= SW(q2); q7 ^= SW(q3); \
	} while (0)

#define MDS_INV   do { \
		q4 ^= SW(q0); q5 ^= SW(q1); q6 ^= SW(q2); q7 ^= SW(q3); \
		q0 ^= q4; q1 ^= q5; q2 ^= q6; q3 ^= q7; \
		MUL_INV(q0, q1, q2, q3); \
		MUL_INV(q0, q1, q2, q3); \
		q4 ^= SW(q0); q5 ^= SW(q1); q6 ^= SW(q2); q7 ^= SW(q3); \
		MUL_INV(q4, q5, q6, q7); \
		q0 ^= q4; q1 ^= q5; q2 ^= q6; q3 ^= q7; \
	} while (0)

#define SR_SLICE   do { \
		q0 = (q0 & 0xFFFF) | ((q0 & 0x33330000) << 2) \
			| ((q0 >> 2) & 0x33330000); \
		q1 = (q1 & 0xFFFF) | ((q1 & 0x33330000) << 2) \
			| ((q1 >> 2) & 0x33330000); \
		q2 = (q2 & 0xFFFF) | ((q2 & 0x33330000) << 2) \
			| ((q2 >> 2) & 0x33330000); \
		q3 = (q3 & 0xFFFF) | ((q3 & 0x33330000) << 2) \
			| ((q3 >> 2) & 0x33330000); \
		q4 = ((q4 & 0x00007777) << 1) | ((q4 >> 3) & 0x00001111) \
			| ((q4 & 0x11110000) << 3) | ((q4 >> 1) & 0x77770000); \
		q5 = ((q5 & 0x00007777) << 1) | ((q5 >> 3) & 0x00001111) \
			| ((q5 & 0x11110000) << 3) | ((q5 >> 1) & 0x77770000); \
		q6 = ((q6 & 0x00007777) << 1) | ((q6 >> 3) & 0x00001111) \
			| ((q6 & 0x11110000) << 3) | ((q6 >> 1) & 0x77770000); \
		q7 = ((q7 & 0x00007777) << 1) | ((q7 >> 3) & 0x00001111) \
			| ((q7 & 0x11110000) << 3) | ((q7 >> 1) & 0x77770000); \
	} while (0)

#define SR_SLICE_INV   do { \
		q0 = (q0 & 0xFFFF) | ((q0 & 0x33330000) << 2) \
			| ((q0 >> 2) & 0x33330000); \
		q1 = (q1 & 0xFFFF) | ((q1 & 0x33330000) << 2) \
			| ((q1 >> 2) & 0x33330000); \
		q2 = (q2 & 0xFFFF) | ((q2 & 0x33330000) << 2) \
			| ((q2 >> 2) & 0x33330000); \
		q3 = (q3 & 0xFFFF) | ((q3 & 0x33330000) << 2) \
			| ((q3 >> 2) & 0x33330000); \
		q4 = ((q4 & 0x00001111) << 3) | ((q4 >> 1) & 0x00007777) \
			| ((q4 & 0x77770000) << 1) | ((q4 >> 3) & 0x11110000); \
		q5 = ((q5 & 0x00001111) << 3) | ((q5 >> 1) & 0x00007777) \
			| ((q5 & 0x77770000) << 1) | ((q5 >> 3) & 0x11110000); \
		q6 = ((q6 & 0x00001111) << 3) | ((q6 >> 1) & 0x00007777) \
			| ((q6 & 0x77770000) << 1) | ((q6 >> 3) & 0x11110000); \
		q7 = ((q7 & 0x00001111) << 3) | ((q7 >> 1) & 0x00007777) \
			| ((q7 & 0x77770000) << 1) | ((q7 >> 3) & 0x11110000); \
	} while (0)

#define SR_SHEET   do { \
		q0 = (q0 & 0xFFFF) | ((q0 & 0x00FF0000) << 8) \
			| ((q0 >> 8) & 0x00FF0000); \
		q1 = (q1 & 0xFFFF) | ((q1 & 0x00FF0000) << 8) \
			| ((q1 >> 8) & 0x00FF0000); \
		q2 = (q2 & 0xFFFF) | ((q2 & 0x00FF0000) << 8) \
			| ((q2 >> 8) & 0x00FF0000); \
		q3 = (q3 & 0xFFFF) | ((q3 & 0x00FF0000) << 8) \
			| ((q3 >> 8) & 0x00FF0000); \
		q4 = ((q4 & 0x00000FFF) << 4) | ((q4 >> 12) & 0x0000000F) \
			| ((q4 & 0x000F0000) << 12) | ((q4 >> 4) & 0x0FFF0000);\
		q5 = ((q5 & 0x00000FFF) << 4) | ((q5 >> 12) & 0x0000000F) \
			| ((q5 & 0x000F0000) << 12) | ((q5 >> 4) & 0x0FFF0000);\
		q6 = ((q6 & 0x00000FFF) << 4) | ((q6 >> 12) & 0x0000000F) \
			| ((q6 & 0x000F0000) << 12) | ((q6 >> 4) & 0x0FFF0000);\
		q7 = ((q7 & 0x00000FFF) << 4) | ((q7 >> 12) & 0x0000000F) \
			| ((q7 & 0x000F0000) << 12) | ((q7 >> 4) & 0x0FFF0000);\
	} while (0)

#define SR_SHEET_INV   do { \
		q0 = (q0 & 0xFFFF) | ((q0 & 0x00FF0000) << 8) \
			| ((q0 >> 8) & 0x00FF0000); \
		q1 = (q1 & 0xFFFF) | ((q1 & 0x00FF0000) << 8) \
			| ((q1 >> 8) & 0x00FF0000); \
		q2 = (q2 & 0xFFFF) | ((q2 & 0x00FF0000) << 8) \
			| ((q2 >> 8) & 0x00FF0000); \
		q3 = (q3 & 0xFFFF) | ((q3 & 0x00FF0000) << 8) \
			| ((q3 >> 8) & 0x00FF0000); \
		q4 = ((q4 & 0x0000000F) << 12) | ((q4 >> 4) & 0x00000FFF) \
			| ((q4 & 0x0FFF0000) << 4) | ((q4 >> 12) & 0x000F0000);\
		q5 = ((q5 & 0x0000000F) << 12) | ((q5 >> 4) & 0x00000FFF) \
			| ((q5 & 0x0FFF0000) << 4) | ((q5 >> 12) & 0x000F0000);\
		q6 = ((q6 & 0x0000000F) << 12) | ((q6 >> 4) & 0x00000FFF) \
			| ((q6 & 0x0FFF0000) << 4) | ((q6 >> 12) & 0x000F0000);\
		q7 = ((q7 & 0x0000000F) << 12) | ((q7 >> 4) & 0x00000FFF) \
			| ((q7 & 0x0FFF0000) << 4) | ((q7 >> 12) & 0x000F0000);\
	} while (0)

#define XOR_KEY   do { \
		q0 ^= keybuf[0]; \
		q1 ^= keybuf[1]; \
		q2 ^= keybuf[2]; \
		q3 ^= keybuf[3]; \
		q4 ^= keybuf[4]; \
		q5 ^= keybuf[5]; \
		q6 ^= keybuf[6]; \
		q7 ^= keybuf[7]; \
	} while (0)

#define XOR_KEY_ROTATED   do { \
		q0 ^= keybuf[ 8]; \
		q1 ^= keybuf[ 9]; \
		q2 ^= keybuf[10]; \
		q3 ^= keybuf[11]; \
		q4 ^= keybuf[12]; \
		q5 ^= keybuf[13]; \
		q6 ^= keybuf[14]; \
		q7 ^= keybuf[15]; \
	} while (0)

/*
 * For Saturnin-CTR-Cascade: R = 10; D = 1, 2, 3, 4 or 5.
 */

static const uint32_t RC_10_1[] = {
	0x4EB026C2, 0x90595303, 0xAA8FE632, 0xFE928A92,
	0x4115A419, 0x93539532, 0x5DB1CC4E, 0x541515CA,
	0xBD1F55A8, 0x5A6E1A0D
};

static const uint32_t RC_10_2[] = {
	0x4E4526B5, 0xA3565FF0, 0x0F8F20D8, 0x0B54BEE1,
	0x7D1A6C9D, 0x17A6280A, 0xAA46C986, 0xC1199062,
	0x182C5CDE, 0xA00D53FE
};

static const uint32_t RC_10_3[] = {
	0x4E162698, 0xB2535BA1, 0x6C8F9D65, 0x5816AD30,
	0x691FD4FA, 0x6BF5BCF9, 0xF8EB3525, 0xB21DECFA,
	0x7B3DA417, 0xF62C94B4
};

static const uint32_t RC_10_4[] = {
	0x4FAF265B, 0xC5484616, 0x45DCAD21, 0xE08BD607,
	0x0504FDB8, 0x1E1F5257, 0x45FBC216, 0xEB529B1F,
	0x52194E32, 0x5498C018
};

static const uint32_t RC_10_5[] = {
	0x4FFC2676, 0xD44D4247, 0x26DC109C, 0xB3C9C5D6,
	0x110145DF, 0x624CC6A4, 0x17563EB5, 0x9856E787,
	0x3108B6FB, 0x02B90752
};

/*
 * For Saturnin-Hash: R = 16; D = 7 or 8.
 */

static const uint32_t RC_16_7[] = {
	0x3FBA180C, 0x563AB9AB, 0x125EA5EF, 0x859DA26C,
	0xB8CF779B, 0x7D4DE793, 0x07EFB49F, 0x8D525306,
	0x1E08E6AB, 0x41729F87, 0x8C4AEF0A, 0x4AA0C9A7,
	0xD93A95EF, 0xBB00D2AF, 0xB62C5BF0, 0x386D94D8
};

static const uint32_t RC_16_8[] = {
	0x3C9B19A7, 0xA9098694, 0x23F878DA, 0xA7B647D3,
	0x74FC9D78, 0xEACAAE11, 0x2F31A677, 0x4CC8C054,
	0x2F51CA05, 0x5268F195, 0x4F5B8A2B, 0xF614B4AC,
	0xF1D95401, 0x764D2568, 0x6A493611, 0x8EEF9C3E
};

/*
 * Exported for benchmarks, but not part of the public API.
 */
void
saturnin_key_expand(uint32_t *keybuf, const uint8_t *key)
{
	int i;

	for (i = 0; i < 8; i ++) {
		uint32_t w;

		w = (uint32_t)key[(i << 1) + 0]
			| ((uint32_t)key[(i << 1) + 1] << 8)
			| ((uint32_t)key[(i << 1) + 16] << 16)
			| ((uint32_t)key[(i << 1) + 17] << 24);
		keybuf[i] = w;
		keybuf[i + 8] = ((w & 0x001F001F) << 11)
			| ((w >> 5) & 0x07FF07FF);
	}
}

/*
 * Perform one Saturnin block encryption.
 *   R        number of super-rounds (0 to 31)
 *   rc       round constants (depends on R and D)
 *   keybuf   key and rotated key (16 words = 64 bytes)
 *   buf      block to encrypt
 * The encrypted block is written back in 'buf'.
 *
 * Exported for benchmarks, but not part of the public API.
 */
void
saturnin_block_encrypt(int R, const uint32_t *rc,
	const uint32_t *keybuf, uint8_t *buf)
{
	DECL_STATE
	int i;

	/*
	 * Decode data into the registers.
	 */
	DEC256(q, buf);

	XOR_KEY;

	/*
	 * Run all rounds (two rounds per super-round, two super-rounds
	 * per loop iteration).
	 */
	for (i = 0; i < R; i += 2) {
		/*
		 * Even round.
		 */
		SBOX;
		MDS;

		/*
		 * Odd round r = 1 mod 4.
		 */
		SBOX;
		SR_SLICE;
		MDS;
		SR_SLICE_INV;
		q0 ^= rc[i + 0];
		XOR_KEY_ROTATED;

		/*
		 * Even round.
		 */
		SBOX;
		MDS;

		/*
		 * Odd round r = 3 mod 4.
		 */
		SBOX;
		SR_SHEET;
		MDS;
		SR_SHEET_INV;
		q0 ^= rc[i + 1];
		XOR_KEY;
	}

	/*
	 * Encode back the result.
	 */
	ENC256(q, buf);
}

/* ======================================================================== */

static void
xor32(uint8_t *dst, const uint8_t *src)
{
	int i;

	for (i = 0; i < 32; i ++) {
		dst[i] ^= src[i];
	}
}

static void
do_cascade(saturnin_aead_context *cc, const uint32_t *rc, const uint8_t *block)
{
	uint32_t kb[16];

	saturnin_key_expand(kb, cc->cascade);
	memcpy(cc->cascade, block, 32);
	saturnin_block_encrypt(10, rc, kb, cc->cascade);
	xor32(cc->cascade, block);
}

void
saturnin_aead_init(saturnin_aead_context *cc,
	const void *key, size_t key_len)
{
	(void)key_len;
	saturnin_key_expand(cc->keybuf, key);
}

void
saturnin_aead_reset(saturnin_aead_context *cc,
	const void *nonce, size_t nonce_len)
{
	/*
	 * Assemble the initial counter value.
	 */
	memcpy(cc->ctr, nonce, nonce_len);
	cc->ctr[nonce_len] = 0x80;
	memset(cc->ctr + nonce_len + 1, 0, 31 - nonce_len);
	memcpy(cc->cascade, cc->ctr, 32);

	/*
	 * Start the cascade.
	 */
	saturnin_block_encrypt(10, RC_10_2, cc->keybuf, cc->cascade);
	xor32(cc->cascade, cc->ctr);

	cc->ptr = 0;
}

void
saturnin_aead_aad_inject(saturnin_aead_context *cc,
	const void *aad, size_t aad_len)
{
	const uint8_t *buf;
	size_t ptr;

	buf = (const uint8_t *)aad;
	ptr = cc->ptr;
	while (aad_len > 0) {
		size_t clen;

		clen = 32 - ptr;
		if (aad_len < clen) {
			memcpy(cc->buf + ptr, buf, aad_len);
			cc->ptr = ptr + aad_len;
			return;
		}
		memcpy(cc->buf + ptr, buf, clen);
		do_cascade(cc, RC_10_2, cc->buf);
		buf += clen;
		aad_len -= clen;
		ptr = 0;
	}
	cc->ptr = ptr;
}

void
saturnin_aead_flip(saturnin_aead_context *cc)
{
	size_t ptr;

	ptr = cc->ptr;
	cc->buf[ptr ++] = 0x80;
	memset(cc->buf + ptr, 0, 32 - ptr);
	do_cascade(cc, RC_10_3, cc->buf);
	cc->ptr = 0;
}

void
saturnin_aead_run(saturnin_aead_context *cc,
	int encrypt, void *data, size_t data_len)
{
	uint8_t *buf;
	size_t ptr;

	buf = (uint8_t *)data;
	ptr = cc->ptr;
	while (data_len > 0) {
		size_t clen;

		/*
		 * If ptr == 0, then the buffer is empty; we fill it
		 * with the encryption of the next counter value.
		 */
		if (ptr == 0) {
			int j;
			unsigned r;

			r = 1;
			for (j = 31; j >= 24; j --) {
				unsigned b;

				b = cc->ctr[j] + r;
				cc->ctr[j] = (uint8_t)b;
				r = b >> 8;
			}
			memcpy(cc->buf, cc->ctr, 32);
			saturnin_block_encrypt(10, RC_10_1,
				cc->keybuf, cc->buf);
		}

		/*
		 * We do the encryption or decryption operations for the few
		 * next bytes. Either way, we take care to keep a copy of
		 * the ciphertext bytes in cc->buf[].
		 */
		clen = 32 - ptr;
		if (clen > data_len) {
			clen = data_len;
		}
		if (encrypt) {
			size_t u;

			for (u = 0; u < clen; u ++) {
				unsigned c;

				c = ((*buf ++) ^= cc->buf[ptr]);
				cc->buf[ptr ++] = c;
			}
		} else {
			size_t u;

			for (u = 0; u < clen; u ++) {
				unsigned c;

				c = *buf;
				*buf ++ ^= cc->buf[ptr];
				cc->buf[ptr ++] = c;
			}
		}
		data_len -= clen;

		/*
		 * When we have processed or produced a full block of
		 * ciphertext, we inject it in the cascade.
		 */
		if (ptr == 32) {
			do_cascade(cc, RC_10_4, cc->buf);
			ptr = 0;
		}
	}
	cc->ptr = ptr;
}

void
saturnin_aead_get_tag(saturnin_aead_context *cc,
	void *tag, size_t tag_len)
{
	size_t ptr;

	/*
	 * Final cascade block.
	 */
	ptr = cc->ptr;
	cc->buf[ptr ++] = 0x80;
	memset(cc->buf + ptr, 0, 32 - ptr);
	do_cascade(cc, RC_10_5, cc->buf);
	memcpy(tag, cc->cascade, tag_len);
}

int
saturnin_aead_check_tag(saturnin_aead_context *cc,
	const void *tag, size_t tag_len)
{
	uint8_t tmp[32];
	int x;
	size_t u;

	saturnin_aead_get_tag(cc, tmp, tag_len);
	x = 0;
	for (u = 0; u < tag_len; u ++) {
		x |= tmp[u] ^ ((const uint8_t *)tag)[u];
	}
	return 1 ^ ((x + 0xFF) >> 8);
}

void
saturnin_hash_init(saturnin_hash_context *hc)
{
	memset(hc->state, 0, 32);
	hc->ptr = 0;
}

void
saturnin_hash_update(saturnin_hash_context *hc,
	const void *data, size_t data_len)
{
	const uint8_t *buf;
	size_t ptr;

	buf = (const uint8_t *)data;
	ptr = hc->ptr;
	while (data_len > 0) {
		size_t clen;
		uint32_t keybuf[16];

		clen = 32 - ptr;
		if (clen > data_len) {
			memcpy(hc->buf + ptr, buf, data_len);
			hc->ptr = ptr + data_len;
			return;
		}
		memcpy(hc->buf + ptr, buf, clen);
		saturnin_key_expand(keybuf, hc->state);
		memcpy(hc->state, hc->buf, 32);
		saturnin_block_encrypt(16, RC_16_7, keybuf, hc->buf);
		xor32(hc->state, hc->buf);
		buf += clen;
		data_len -= clen;
		ptr = 0;
	}
	hc->ptr = ptr;
}

void
saturnin_hash_out(const saturnin_hash_context *hc,
	void *out)
{
	uint32_t keybuf[32];
	size_t ptr, u;
	uint8_t *buf;

	ptr = hc->ptr;
	buf = (uint8_t *)out;
	memcpy(buf, hc->buf, ptr);
	buf[ptr] = 0x80;
	memset(buf + ptr + 1, 0, 31 - ptr);
	saturnin_key_expand(keybuf, hc->state);
	saturnin_block_encrypt(16, RC_16_8, keybuf, buf);
	for (u = 0; u < ptr; u ++) {
		buf[u] ^= hc->buf[u];
	}
	buf[ptr] ^= 0x80;
}
