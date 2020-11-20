@ =======================================================================
@ Combined Saturnin-CTR-Cascade and Saturnin-Hash implementation for
@ ARM Cortex-M4 CPU. This implements the API described in saturnin.h.
@ =======================================================================

	.syntax	unified
	.cpu	cortex-m4
	.file	"saturnin_m4.s"
	.text

@ =======================================================================
@ void saturnin_key_expand(uint32_t *keybuf, const uint8_t *key)
@
@   Read 32-byte key (possibly unaligned) and convert it to the internal
@   bitslice-32 representation (key bytes yield sixteen 16-bit registers
@   z0 to z15; internal representation is eight 32-bit words k0..k7
@   such that k_i = z_i | (z_{i+8} << 16)).
@   The words k_i are written in keybuf[]. Then they are written again,
@   this time with the extra "key rotation". In total, sixteen 32-bit
@   words are written in keybuf[].
@ =======================================================================
	.align	1
	.global	saturnin_key_expand
	.thumb
	.thumb_func
	.type	saturnin_key_expand, %function
saturnin_key_expand:
	push	{r4, r5, r6, r7, r8, lr}

	@ Set r12 = 0x001F001F and r8 = 0x07FF07FF
	movs	r2, #0x1F
	orr	r12, r2, r2, lsl #16
	mvn	r8, r12, lsl #11

	@ Make words q0...q3
	ldr	r2, [r1]
	ldr	r3, [r1, #16]
	pkhbt	r4, r2, r3, lsl #16
	pkhtb	r5, r3, r2, asr #16
	ldr	r2, [r1, #4]
	ldr	r3, [r1, #20]
	pkhbt	r6, r2, r3, lsl #16
	pkhtb	r7, r3, r2, asr #16
	stm	r0!, {r4, r5, r6, r7}

	@ Apply rotations on q0..q3
	and	r2, r8, r4, lsr #5
	and	r3, r12, r4
	orr	r4, r2, r3, lsl #11
	and	r2, r8, r5, lsr #5
	and	r3, r12, r5
	orr	r5, r2, r3, lsl #11
	and	r2, r8, r6, lsr #5
	and	r3, r12, r6
	orr	r6, r2, r3, lsl #11
	and	r2, r8, r7, lsr #5
	and	r3, r12, r7
	orr	r7, r2, r3, lsl #11
	adds	r0, #16
	stm	r0!, {r4, r5, r6, r7}

	@ Make words q4...q7
	ldr	r2, [r1, #8]
	ldr	r3, [r1, #24]
	pkhbt	r4, r2, r3, lsl #16
	pkhtb	r5, r3, r2, asr #16
	ldr	r2, [r1, #12]
	ldr	r3, [r1, #28]
	pkhbt	r6, r2, r3, lsl #16
	pkhtb	r7, r3, r2, asr #16
	subs	r0, #32
	stm	r0!, {r4, r5, r6, r7}

	@ Apply rotations on q4..q7
	and	r2, r8, r4, lsr #5
	and	r3, r12, r4
	orr	r4, r2, r3, lsl #11
	and	r2, r8, r5, lsr #5
	and	r3, r12, r5
	orr	r5, r2, r3, lsl #11
	and	r2, r8, r6, lsr #5
	and	r3, r12, r6
	orr	r6, r2, r3, lsl #11
	and	r2, r8, r7, lsr #5
	and	r3, r12, r7
	orr	r7, r2, r3, lsl #11
	add	r0, #16
	stm	r0!, {r4, r5, r6, r7}

	pop	{r4, r5, r6, r7, r8, pc}
	.size	saturnin_key_expand, .-saturnin_key_expand

@ =======================================================================
@ void saturnin_block_encrypt(int R, const uint32_t *rc,
@                             uint32_t *keybuf, const uint8_t *buf)
@
@   Perform one block encryption:
@     R        Number of super-rounds (typically 10 or 16); must be even.
@     rc       The round constants, in usage order.
@     keybuf   The key and the rotated key.
@     buf      The input/output block (possibly unaligned).
@
@   The key and rotated key are in internal representation, as output
@   by saturnin_key_expand(). Each round constant is a 32-bit word;
@   low 16 bits are RC0, high 16 bits are RC1.
@ =======================================================================
	.align	1
	.global	saturnin_block_encrypt
	.thumb
	.thumb_func
	.type	saturnin_block_encrypt, %function
saturnin_block_encrypt:
	push	{r0, r1, r2, r3, r4, r5, r6, r7, r8, r10, r11, lr}

	@ Conventions:
	@   r0..r7    state values q0..q7
	@   [sp]      super-round counter
	@   [sp+4]    pointer to next round constant
	@   [sp+8]    pointer to key buf
	@   [sp+12]   pointer to data block
	@ Reserved registers are r9, r13 (sp) and r15 (pc).
	@ Scratch registers are r8, r10, r11, r12 and r14.

	@ Read block into q0..q7
	ldr	r0, [r3, #8]
	ldr	r1, [r3, #24]
	pkhbt	r4, r0, r1, lsl #16
	pkhtb	r5, r1, r0, asr #16
	ldr	r0, [r3, #12]
	ldr	r1, [r3, #28]
	pkhbt	r6, r0, r1, lsl #16
	pkhtb	r7, r1, r0, asr #16
	ldr	r0, [r3, #4]
	ldr	r1, [r3, #20]
	pkhbt	r2, r0, r1, lsl #16
	pkhtb	r12, r1, r0, asr #16
	ldr	r0, [r3, #0]
	ldr	r1, [r3, #16]
	pkhbt	r14, r0, r1, lsl #16
	pkhtb	r1, r1, r0, asr #16
	movs	r3, r12
	movs	r0, r14

	@ XOR with key
	ldr	r8, [sp, #8]
	ldm	r8!, {r10, r11, r12, r14}
	eors	r0, r10
	eors	r1, r11
	eors	r2, r12
	eors	r3, r14
	ldm	r8!, {r10, r11, r12, r14}
	eors	r4, r10
	eors	r5, r11
	eors	r6, r12
	eors	r7, r14

.Lsaturnin_block_encrypt_loop:
	@ ============= Even round

	@ Apply Sbox
	ands	r8, r1, r2
	eors	r8, r0, r8     @ r8 r1 r2 r3
	orrs	r10, r8, r3
	eors	r10, r1, r10   @ r8 r10 r2 r3
	orrs	r11, r10, r2
	eors	r11, r3, r11   @ r8 r10 r2 r11
	ands	r1, r10, r11
	eors	r1, r2, r1     @ r8 r10 r1 r11
	orrs	r0, r8, r1
	eors	r0, r10, r0    @ r8 r0 r1 r11
	orrs	r3, r0, r11
	eors	r3, r8, r3     @ r3 r0 r1 r11
	movs	r2, r11        @ r3 r0 r1 r2

	ands	r8, r5, r6
	eors	r8, r4, r8     @ r8 r5 r6 r7
	orrs	r10, r8, r7
	eors	r5, r5, r10    @ r8 r5 r6 r7
	orrs	r4, r5, r6
	eors	r4, r7, r4     @ r8 r5 r6 r4
	ands	r7, r5, r4
	eors	r7, r6, r7     @ r8 r5 r7 r4
	orrs	r11, r8, r7
	eors	r5, r5, r11    @ r8 r5 r7 r4
	orrs	r6, r5, r4
	eors	r6, r8, r6     @ r6 r5 r7 r4

	@ Apply MDS
	@ Initial: state is: r0 r1 r2 r3 r4 r5 r6 r7

	@ q0 ^= q4; q1 ^= q5; q2 ^= q6; q3 ^= q7;
	eors	r0, r4
	eors	r1, r5
	eors	r2, r6
	eors	r3, r7

	@ MUL(q4, q5, q6, q7);
	eors	r4, r5     @ r0 r1 r2 r3 r5 r6 r7 r4

	@ q4 ^= SW(q0); q5 ^= SW(q1); q6 ^= SW(q2); q7 ^= SW(q3);
	eors	r5, r5, r0, ror #16
	eors	r6, r6, r1, ror #16
	eors	r7, r7, r2, ror #16
	eors	r4, r4, r3, ror #16

	@ MUL(q0, q1, q2, q3);
	eors	r0, r1     @ r1 r2 r3 r0 r5 r6 r7 r4
	@ MUL(q0, q1, q2, q3);
	eors	r1, r2     @ r2 r3 r0 r1 r5 r6 r7 r4

	@ q0 ^= q4; q1 ^= q5; q2 ^= q6; q3 ^= q7;
	eors	r2, r5
	eors	r3, r6
	eors	r0, r7
	eors	r1, r4

	@ q4 ^= SW(q0); q5 ^= SW(q1); q6 ^= SW(q2); q7 ^= SW(q3);
	eors	r5, r5, r2, ror #16
	eors	r6, r6, r3, ror #16
	eors	r7, r7, r0, ror #16
	eors	r4, r4, r1, ror #16

	@ At this point, we have the following mapping:
	@   q0  in  r2
	@   q1  in  r3
	@   q2  in  r0
	@   q3  in  r1
	@   q4  in  r5
	@   q5  in  r6
	@   q6  in  r7
	@   q7  in  r4

	@ ============= Odd round, r = 1 mod 4

	@ Apply Sbox
	ands	r8, r3, r0
	eors	r8, r2, r8     @ r8 r3 r0 r1
	orrs	r10, r8, r1
	eors	r10, r3, r10   @ r8 r10 r0 r1
	orrs	r11, r10, r0
	eors	r11, r1, r11   @ r8 r10 r0 r11
	ands	r3, r10, r11
	eors	r3, r0, r3     @ r8 r10 r3 r11
	orrs	r2, r8, r3
	eors	r2, r10, r2    @ r8 r2 r3 r11
	orrs	r1, r2, r11
	eors	r1, r8, r1     @ r1 r2 r3 r11
	movs	r0, r11        @ r1 r2 r3 r0

	ands	r8, r6, r7
	eors	r8, r5, r8     @ r8 r6 r7 r4
	orrs	r10, r8, r4
	eors	r6, r6, r10    @ r8 r6 r7 r4
	orrs	r5, r6, r7
	eors	r5, r4, r5     @ r8 r6 r7 r5
	ands	r4, r6, r5
	eors	r4, r7, r4     @ r8 r6 r4 r5
	orrs	r11, r8, r4
	eors	r6, r6, r11    @ r8 r6 r4 r5
	orrs	r7, r6, r5
	eors	r7, r8, r7     @ r7 r6 r4 r5

	@ Apply SR_slice
	movw	r8, #0x3333
	movw	r10, #0xCCCC
	ands	r11, r8, r2, lsr #18
	ands	r12, r10, r2, lsr #14
	orrs	r12, r11, r12
	pkhbt	r2, r2, r12, lsl #16
	ands	r11, r8, r3, lsr #18
	ands	r12, r10, r3, lsr #14
	orrs	r12, r11, r12
	pkhbt	r3, r3, r12, lsl #16
	ands	r11, r8, r0, lsr #18
	ands	r12, r10, r0, lsr #14
	orrs	r12, r11, r12
	pkhbt	r0, r0, r12, lsl #16
	ands	r11, r8, r1, lsr #18
	ands	r12, r10, r1, lsr #14
	orrs	r12, r11, r12
	pkhbt	r1, r1, r12, lsl #16
	movw	r8, #0x1111
	movw	r10, #0xEEEE
	ands	r11, r10, r5, lsl #1      @ (x & 0x00007777) << 1 -> r11
	ands	r12, r8, r5, lsr #3       @ (x >> 3) & 0x00001111 -> r12
	orrs	r14, r11, r12
	ands	r11, r8, r5, lsr #16      @ (x >> 16) & 0x00001111 -> r11
	ands	r12, r10, r5, lsr #16     @ (x >> 16) & 0x0000EEEE -> r12
	orrs	r5, r14, r11, lsl #19
	orrs	r5, r5, r12, lsl #15
	ands	r11, r10, r6, lsl #1      @ (x & 0x00007777) << 1 -> r11
	ands	r12, r8, r6, lsr #3       @ (x >> 3) & 0x00001111 -> r12
	orrs	r14, r11, r12
	ands	r11, r8, r6, lsr #16      @ (x >> 16) & 0x00001111 -> r11
	ands	r12, r10, r6, lsr #16     @ (x >> 16) & 0x0000EEEE -> r12
	orrs	r6, r14, r11, lsl #19
	orrs	r6, r6, r12, lsl #15
	ands	r11, r10, r7, lsl #1      @ (x & 0x00007777) << 1 -> r11
	ands	r12, r8, r7, lsr #3       @ (x >> 3) & 0x00001111 -> r12
	orrs	r14, r11, r12
	ands	r11, r8, r7, lsr #16      @ (x >> 16) & 0x00001111 -> r11
	ands	r12, r10, r7, lsr #16     @ (x >> 16) & 0x0000EEEE -> r12
	orrs	r7, r14, r11, lsl #19
	orrs	r7, r7, r12, lsl #15
	ands	r11, r10, r4, lsl #1      @ (x & 0x00007777) << 1 -> r11
	ands	r12, r8, r4, lsr #3       @ (x >> 3) & 0x00001111 -> r12
	orrs	r14, r11, r12
	ands	r11, r8, r4, lsr #16      @ (x >> 16) & 0x00001111 -> r11
	ands	r12, r10, r4, lsr #16     @ (x >> 16) & 0x0000EEEE -> r12
	orrs	r4, r14, r11, lsl #19
	orrs	r4, r4, r12, lsl #15

	@ Apply MDS
	@ Initial: state is: r2 r3 r0 r1 r5 r6 r7 r4

	@ q0 ^= q4; q1 ^= q5; q2 ^= q6; q3 ^= q7;
	eors	r2, r5
	eors	r3, r6
	eors	r0, r7
	eors	r1, r4

	@ MUL(q4, q5, q6, q7);
	eors	r5, r6     @ r2 r3 r0 r1 r6 r7 r4 r5

	@ q4 ^= SW(q0); q5 ^= SW(q1); q6 ^= SW(q2); q7 ^= SW(q3);
	eors	r6, r6, r2, ror #16
	eors	r7, r7, r3, ror #16
	eors	r4, r4, r0, ror #16
	eors	r5, r5, r1, ror #16

	@ MUL(q0, q1, q2, q3);
	eors	r2, r3     @ r3 r0 r1 r2 r6 r7 r4 r5
	@ MUL(q0, q1, q2, q3);
	eors	r3, r0     @ r0 r1 r2 r3 r6 r7 r4 r5

	@ q0 ^= q4; q1 ^= q5; q2 ^= q6; q3 ^= q7;
	eors	r0, r6
	eors	r1, r7
	eors	r2, r4
	eors	r3, r5

	@ q4 ^= SW(q0); q5 ^= SW(q1); q6 ^= SW(q2); q7 ^= SW(q3);
	eors	r6, r6, r0, ror #16
	eors	r7, r7, r1, ror #16
	eors	r4, r4, r2, ror #16
	eors	r5, r5, r3, ror #16

	@ At this point, we have the following mapping:
	@   q0  in  r0
	@   q1  in  r1
	@   q2  in  r2
	@   q3  in  r3
	@   q4  in  r6
	@   q5  in  r7
	@   q6  in  r4
	@   q7  in  r5

	@ Apply SR_slice_inv
	movw	r8, #0x3333
	movw	r10, #0xCCCC
	ands	r11, r8, r0, lsr #18
	ands	r12, r10, r0, lsr #14
	orrs	r12, r11, r12
	pkhbt	r0, r0, r12, lsl #16
	ands	r11, r8, r1, lsr #18
	ands	r12, r10, r1, lsr #14
	orrs	r12, r11, r12
	pkhbt	r1, r1, r12, lsl #16
	ands	r11, r8, r2, lsr #18
	ands	r12, r10, r2, lsr #14
	orrs	r12, r11, r12
	pkhbt	r2, r2, r12, lsl #16
	ands	r11, r8, r3, lsr #18
	ands	r12, r10, r3, lsr #14
	orrs	r12, r11, r12
	pkhbt	r3, r3, r12, lsl #16
	movw	r8, #0x7777
	movw	r10, #0x8888
	ands	r11, r10, r6, lsl #3      @ (x & 0x00001111) << 3 -> r11
	ands	r12, r8, r6, lsr #1       @ (x >> 1) & 0x00007777 -> r12
	orrs	r14, r11, r12
	ands	r11, r8, r6, lsr #16      @ (x >> 16) & 0x00007777 -> r11
	ands	r12, r10, r6, lsr #16     @ (x >> 16) & 0x00008888 -> r12
	orrs	r6, r14, r11, lsl #17
	orrs	r6, r6, r12, lsl #13
	ands	r11, r10, r7, lsl #3      @ (x & 0x00001111) << 3 -> r11
	ands	r12, r8, r7, lsr #1       @ (x >> 1) & 0x00007777 -> r12
	orrs	r14, r11, r12
	ands	r11, r8, r7, lsr #16      @ (x >> 16) & 0x00007777 -> r11
	ands	r12, r10, r7, lsr #16     @ (x >> 16) & 0x00008888 -> r12
	orrs	r7, r14, r11, lsl #17
	orrs	r7, r7, r12, lsl #13
	ands	r11, r10, r4, lsl #3      @ (x & 0x00001111) << 3 -> r11
	ands	r12, r8, r4, lsr #1       @ (x >> 1) & 0x00007777 -> r12
	orrs	r14, r11, r12
	ands	r11, r8, r4, lsr #16      @ (x >> 16) & 0x00007777 -> r11
	ands	r12, r10, r4, lsr #16     @ (x >> 16) & 0x00008888 -> r12
	orrs	r4, r14, r11, lsl #17
	orrs	r4, r4, r12, lsl #13
	ands	r11, r10, r5, lsl #3      @ (x & 0x00001111) << 3 -> r11
	ands	r12, r8, r5, lsr #1       @ (x >> 1) & 0x00007777 -> r12
	orrs	r14, r11, r12
	ands	r11, r8, r5, lsr #16      @ (x >> 16) & 0x00007777 -> r11
	ands	r12, r10, r5, lsr #16     @ (x >> 16) & 0x00008888 -> r12
	orrs	r5, r14, r11, lsl #17
	orrs	r5, r5, r12, lsl #13

	@ XOR round constant
	ldr	r8, [sp, #4]
	ldm	r8!, {r10}
	str	r8, [sp, #4]
	eors	r0, r10

	@ XOR rotated key
	ldr	r8, [sp, #8]
	adds	r8, #32
	ldm	r8!, {r10, r11, r12, r14}
	eors	r0, r10
	eors	r1, r11
	eors	r2, r12
	eors	r3, r14
	ldm	r8!, {r10, r11, r12, r14}
	eors	r6, r10
	eors	r7, r11
	eors	r4, r12
	eors	r5, r14

	@ ============= Even round

	@ Apply Sbox
	ands	r8, r1, r2
	eors	r8, r0, r8     @ r8 r1 r2 r3
	orrs	r10, r8, r3
	eors	r10, r1, r10   @ r8 r10 r2 r3
	orrs	r11, r10, r2
	eors	r11, r3, r11   @ r8 r10 r2 r11
	ands	r1, r10, r11
	eors	r1, r2, r1     @ r8 r10 r1 r11
	orrs	r0, r8, r1
	eors	r0, r10, r0    @ r8 r0 r1 r11
	orrs	r3, r0, r11
	eors	r3, r8, r3     @ r3 r0 r1 r11
	movs	r2, r11        @ r3 r0 r1 r2

	ands	r8, r7, r4
	eors	r8, r6, r8     @ r8 r7 r4 r5
	orrs	r10, r8, r5
	eors	r7, r7, r10    @ r8 r7 r4 r5
	orrs	r6, r7, r4
	eors	r6, r5, r6     @ r8 r7 r4 r6
	ands	r5, r7, r6
	eors	r5, r4, r5     @ r8 r7 r5 r6
	orrs	r11, r8, r5
	eors	r7, r7, r11    @ r8 r7 r5 r6
	orrs	r4, r7, r6
	eors	r4, r8, r4     @ r4 r7 r5 r6

	@ Apply MDS
	@ Initial: state is: r0 r1 r2 r3 r6 r7 r4 r5

	@ q0 ^= q4; q1 ^= q5; q2 ^= q6; q3 ^= q7;
	eors	r0, r6
	eors	r1, r7
	eors	r2, r4
	eors	r3, r5

	@ MUL(q4, q5, q6, q7);
	eors	r6, r7     @ r0 r1 r2 r3 r7 r4 r5 r6

	@ q4 ^= SW(q0); q5 ^= SW(q1); q6 ^= SW(q2); q7 ^= SW(q3);
	eors	r7, r7, r0, ror #16
	eors	r4, r4, r1, ror #16
	eors	r5, r5, r2, ror #16
	eors	r6, r6, r3, ror #16

	@ MUL(q0, q1, q2, q3);
	eors	r0, r1     @ r1 r2 r3 r0 r7 r4 r5 r6
	@ MUL(q0, q1, q2, q3);
	eors	r1, r2     @ r2 r3 r0 r1 r7 r4 r5 r6

	@ q0 ^= q4; q1 ^= q5; q2 ^= q6; q3 ^= q7;
	eors	r2, r7
	eors	r3, r4
	eors	r0, r5
	eors	r1, r6

	@ q4 ^= SW(q0); q5 ^= SW(q1); q6 ^= SW(q2); q7 ^= SW(q3);
	eors	r7, r7, r2, ror #16
	eors	r4, r4, r3, ror #16
	eors	r5, r5, r0, ror #16
	eors	r6, r6, r1, ror #16

	@ At this point, we have the following mapping:
	@   q0  in  r2
	@   q1  in  r3
	@   q2  in  r0
	@   q3  in  r1
	@   q4  in  r7
	@   q5  in  r4
	@   q6  in  r5
	@   q7  in  r6

	@ ============= Odd round, r = 3 mod 4

	@ Apply Sbox
	ands	r8, r3, r0
	eors	r8, r2, r8     @ r8 r3 r0 r1
	orrs	r10, r8, r1
	eors	r10, r3, r10   @ r8 r10 r0 r1
	orrs	r11, r10, r0
	eors	r11, r1, r11   @ r8 r10 r0 r11
	ands	r3, r10, r11
	eors	r3, r0, r3     @ r8 r10 r3 r11
	orrs	r2, r8, r3
	eors	r2, r10, r2    @ r8 r2 r3 r11
	orrs	r1, r2, r11
	eors	r1, r8, r1     @ r1 r2 r3 r11
	movs	r0, r11        @ r1 r2 r3 r0

	ands	r8, r4, r5
	eors	r8, r7, r8     @ r8 r4 r5 r6
	orrs	r10, r8, r6
	eors	r4, r4, r10    @ r8 r4 r5 r6
	orrs	r7, r4, r5
	eors	r7, r6, r7     @ r8 r4 r5 r7
	ands	r6, r4, r7
	eors	r6, r5, r6     @ r8 r4 r6 r7
	orrs	r11, r8, r6
	eors	r4, r4, r11    @ r8 r4 r6 r7
	orrs	r5, r4, r7
	eors	r5, r8, r5     @ r5 r4 r6 r7

	@ Apply SR_sheet
	rev	r8, r2
	pkhbt	r2, r2, r8, lsl #16
	rev	r8, r3
	pkhbt	r3, r3, r8, lsl #16
	rev	r8, r0
	pkhbt	r0, r0, r8, lsl #16
	rev	r8, r1
	pkhbt	r1, r1, r8, lsl #16
	pkhbt	r10, r7, r7, lsl #16
	pkhtb	r11, r7, r7, asr #16
	ror	r10, r10, #12
	ror	r11, r11, #4
	pkhbt	r7, r10, r11
	pkhbt	r10, r4, r4, lsl #16
	pkhtb	r11, r4, r4, asr #16
	ror	r10, r10, #12
	ror	r11, r11, #4
	pkhbt	r4, r10, r11
	pkhbt	r10, r5, r5, lsl #16
	pkhtb	r11, r5, r5, asr #16
	ror	r10, r10, #12
	ror	r11, r11, #4
	pkhbt	r5, r10, r11
	pkhbt	r10, r6, r6, lsl #16
	pkhtb	r11, r6, r6, asr #16
	ror	r10, r10, #12
	ror	r11, r11, #4
	pkhbt	r6, r10, r11

	@ Apply MDS
	@ Initial: state is: r2 r3 r0 r1 r7 r4 r5 r6

	@ q0 ^= q4; q1 ^= q5; q2 ^= q6; q3 ^= q7;
	eors	r2, r7
	eors	r3, r4
	eors	r0, r5
	eors	r1, r6

	@ MUL(q4, q5, q6, q7);
	eors	r7, r4     @ r2 r3 r0 r1 r4 r5 r6 r7

	@ q4 ^= SW(q0); q5 ^= SW(q1); q6 ^= SW(q2); q7 ^= SW(q3);
	eors	r4, r4, r2, ror #16
	eors	r5, r5, r3, ror #16
	eors	r6, r6, r0, ror #16
	eors	r7, r7, r1, ror #16

	@ MUL(q0, q1, q2, q3);
	eors	r2, r3     @ r3 r0 r1 r2 r4 r5 r6 r7
	@ MUL(q0, q1, q2, q3);
	eors	r3, r0     @ r0 r1 r2 r3 r4 r5 r6 r7

	@ q0 ^= q4; q1 ^= q5; q2 ^= q6; q3 ^= q7;
	eors	r0, r4
	eors	r1, r5
	eors	r2, r6
	eors	r3, r7

	@ q4 ^= SW(q0); q5 ^= SW(q1); q6 ^= SW(q2); q7 ^= SW(q3);
	eors	r4, r4, r0, ror #16
	eors	r5, r5, r1, ror #16
	eors	r6, r6, r2, ror #16
	eors	r7, r7, r3, ror #16

	@ At this point, we have the following mapping:
	@   q0  in  r0
	@   q1  in  r1
	@   q2  in  r2
	@   q3  in  r3
	@   q4  in  r4
	@   q5  in  r5
	@   q6  in  r6
	@   q7  in  r7

	@ Apply SR_sheet_inv
	rev	r8, r0
	pkhbt	r0, r0, r8, lsl #16
	rev	r8, r1
	pkhbt	r1, r1, r8, lsl #16
	rev	r8, r2
	pkhbt	r2, r2, r8, lsl #16
	rev	r8, r3
	pkhbt	r3, r3, r8, lsl #16
	pkhbt	r10, r4, r4, lsl #16
	pkhtb	r11, r4, r4, asr #16
	ror	r10, r10, #4
	ror	r11, r11, #12
	pkhbt	r4, r10, r11
	pkhbt	r10, r5, r5, lsl #16
	pkhtb	r11, r5, r5, asr #16
	ror	r10, r10, #4
	ror	r11, r11, #12
	pkhbt	r5, r10, r11
	pkhbt	r10, r6, r6, lsl #16
	pkhtb	r11, r6, r6, asr #16
	ror	r10, r10, #4
	ror	r11, r11, #12
	pkhbt	r6, r10, r11
	pkhbt	r10, r7, r7, lsl #16
	pkhtb	r11, r7, r7, asr #16
	ror	r10, r10, #4
	ror	r11, r11, #12
	pkhbt	r7, r10, r11

	@ XOR round constant
	ldr	r8, [sp, #4]
	ldm	r8!, {r10}
	str	r8, [sp, #4]
	eors	r0, r10

	@ XOR non-rotated key
	ldr	r8, [sp, #8]
	ldm	r8!, {r10, r11, r12, r14}
	eors	r0, r10
	eors	r1, r11
	eors	r2, r12
	eors	r3, r14
	ldm	r8!, {r10, r11, r12, r14}
	eors	r4, r10
	eors	r5, r11
	eors	r6, r12
	eors	r7, r14

	@ Loop for sufficiently many rounds.
	ldr	r8, [sp]
	subs	r8, #2
	str	r8, [sp]
	bne	.Lsaturnin_block_encrypt_loop

	@ Encode back the final state.
	ldr	r8, [sp, #12]
	pkhbt	r10, r0, r1, lsl #16
	str	r10, [r8]
	pkhbt	r10, r2, r3, lsl #16
	str	r10, [r8, #4]
	pkhbt	r10, r4, r5, lsl #16
	str	r10, [r8, #8]
	pkhbt	r10, r6, r7, lsl #16
	str	r10, [r8, #12]
	pkhtb	r10, r1, r0, asr #16
	str	r10, [r8, #16]
	pkhtb	r10, r3, r2, asr #16
	str	r10, [r8, #20]
	pkhtb	r10, r5, r4, asr #16
	str	r10, [r8, #24]
	pkhtb	r10, r7, r6, asr #16
	str	r10, [r8, #28]

	pop	{r0, r1, r2, r3, r4, r5, r6, r7, r8, r10, r11, pc}
	.size	saturnin_block_encrypt, .-saturnin_block_encrypt

@ =======================================================================
@ void xor32_aligned(uint8_t *dst, const uint8_t *src)
@
@   XOR the 32 bytes from src[] into the 32 bytes at dst[]. Both src[]
@   and dst[] MUST be 32-byte aligned.
@ =======================================================================
	.align	1
	.thumb
	.thumb_func
	.type	xor32_aligned, %function
xor32_aligned:
	push	{r0, r4, r5, r6, r7, lr}   @ r0 is for stack 8-byte alignment
	ldm	r0, {r2, r3, r4, r5}
	ldm	r1!, {r6, r7, r12, r14}
	eors	r2, r6
	eors	r3, r7
	eors	r4, r12
	eors	r5, r14
	stm	r0!, {r2, r3, r4, r5}
	ldm	r0, {r2, r3, r4, r5}
	ldm	r1!, {r6, r7, r12, r14}
	eors	r2, r6
	eors	r3, r7
	eors	r4, r12
	eors	r5, r14
	stm	r0!, {r2, r3, r4, r5}
	pop	{r0, r4, r5, r6, r7, pc}
	.size	xor32_aligned, .-xor32_aligned

@ =======================================================================
@ Saturnin-CTR-Cascade (AEAD mode).
@
@ The context is the following structure (declared in saturnin.h):
@
@   typedef struct {
@           uint32_t keybuf[16];
@           uint8_t cascade[32];
@           uint8_t ctr[32];
@           uint8_t buf[32];
@           size_t ptr;
@   } saturnin_aead_context;
@
@ =======================================================================

@ =======================================================================
@ void do_cascade(saturnin_aead_context *cc, const uint32_t *rc)
@
@   Apply the Cascade for one more block. The block is cc->buf[].
@   This uses the current cascade[] field as key for a Saturnin block
@   encryption (10 super-rounds); the input of that block encryption
@   is cc->buf[]; the XOR of the output with the input block becomes the
@   new cascade[] field.
@ =======================================================================
	.align	1
	.thumb
	.thumb_func
	.type	do_cascade_aligned, %function
do_cascade_aligned:
	push	{r1, r4, r5, lr}

	@ We set r4 to the cascade[] field within the context,
	@ and r5 to the buf[] address.
	adds	r5, r0, #128
	adds	r4, r0, #64

	@ Expand the current cascade[] as a key into a stack allocated
	@ keybuf[].
	sub	sp, sp, #64
	mov	r0, sp
	movs	r1, r4
	bl	saturnin_key_expand

	@ Copy the block[] into the cascade[] field. We assume that both
	@ are aligned.
	ldm	r5!, {r0, r1, r2, r3}
	stm	r4!, {r0, r1, r2, r3}
	ldm	r5!, {r0, r1, r2, r3}
	stm	r4!, {r0, r1, r2, r3}
	subs	r5, #32
	subs	r4, #32

	@ Perform the block encryption.
	movs	r0, #10
	ldr	r1, [sp, #64]
	mov	r2, sp
	movs	r3, r4
	bl	saturnin_block_encrypt

	@ XOR the input block with the encryption output.
	movs	r0, r4
	movs	r1, r5
	bl	xor32_aligned

	@ Exit. We must add 64 for the stack-allocated keybuf[], and 4 for
	@ the r1 which was saved.
	add	sp, sp, #68
	pop	{r4, r5, pc}
	.size	do_cascade_aligned, .-do_cascade_aligned

@ =======================================================================
@ void saturnin_aead_init(saturnin_aead_context *cc,
@                 const void *key, size_t key_len)
@
@   Initialize the context with the provided key. The 'key_len' field
@   is ignored (it is up to the caller to make sure that only 32-byte
@   keys are provided).
@ =======================================================================
	.align	1
	.global	saturnin_aead_init
	.thumb
	.thumb_func
	.type	saturnin_aead_init, %function
saturnin_aead_init:
	@ Initialization is just expanding the key into the keybuf[]
	@ field of the context, which is at offset 0.
	b	saturnin_key_expand
	.size	saturnin_aead_init, .-saturnin_aead_init

@ =======================================================================
@ Precomputed round constants.
@ =======================================================================
	.align	2

	.type	.RC_10_1, %object
	.size	.RC_10_1, 40
.RC_10_1:
	.word	0x4EB026C2
	.word	0x90595303
	.word	0xAA8FE632
	.word	0xFE928A92
	.word	0x4115A419
	.word	0x93539532
	.word	0x5DB1CC4E
	.word	0x541515CA
	.word	0xBD1F55A8
	.word	0x5A6E1A0D

	.type	.RC_10_2, %object
	.size	.RC_10_2, 40
.RC_10_2:
	.word	0x4E4526B5
	.word	0xA3565FF0
	.word	0x0F8F20D8
	.word	0x0B54BEE1
	.word	0x7D1A6C9D
	.word	0x17A6280A
	.word	0xAA46C986
	.word	0xC1199062
	.word	0x182C5CDE
	.word	0xA00D53FE

	.type	.RC_10_3, %object
	.size	.RC_10_3, 40
.RC_10_3:
	.word	0x4E162698
	.word	0xB2535BA1
	.word	0x6C8F9D65
	.word	0x5816AD30
	.word	0x691FD4FA
	.word	0x6BF5BCF9
	.word	0xF8EB3525
	.word	0xB21DECFA
	.word	0x7B3DA417
	.word	0xF62C94B4

	.type	.RC_10_4, %object
	.size	.RC_10_4, 40
.RC_10_4:
	.word	0x4FAF265B
	.word	0xC5484616
	.word	0x45DCAD21
	.word	0xE08BD607
	.word	0x0504FDB8
	.word	0x1E1F5257
	.word	0x45FBC216
	.word	0xEB529B1F
	.word	0x52194E32
	.word	0x5498C018

	.type	.RC_10_5, %object
	.size	.RC_10_5, 40
.RC_10_5:
	.word	0x4FFC2676
	.word	0xD44D4247
	.word	0x26DC109C
	.word	0xB3C9C5D6
	.word	0x110145DF
	.word	0x624CC6A4
	.word	0x17563EB5
	.word	0x9856E787
	.word	0x3108B6FB
	.word	0x02B90752

	.type	.RC_16_7, %object
	.size	.RC_16_7, 64
.RC_16_7:
	.word	0x3FBA180C
	.word	0x563AB9AB
	.word	0x125EA5EF
	.word	0x859DA26C
	.word	0xB8CF779B
	.word	0x7D4DE793
	.word	0x07EFB49F
	.word	0x8D525306
	.word	0x1E08E6AB
	.word	0x41729F87
	.word	0x8C4AEF0A
	.word	0x4AA0C9A7
	.word	0xD93A95EF
	.word	0xBB00D2AF
	.word	0xB62C5BF0
	.word	0x386D94D8

	.type	.RC_16_8, %object
	.size	.RC_16_8, 64
.RC_16_8:
	.word	0x3C9B19A7
	.word	0xA9098694
	.word	0x23F878DA
	.word	0xA7B647D3
	.word	0x74FC9D78
	.word	0xEACAAE11
	.word	0x2F31A677
	.word	0x4CC8C054
	.word	0x2F51CA05
	.word	0x5268F195
	.word	0x4F5B8A2B
	.word	0xF614B4AC
	.word	0xF1D95401
	.word	0x764D2568
	.word	0x6A493611
	.word	0x8EEF9C3E

@ =======================================================================
@ void saturnin_aead_reset(saturnin_aead_context *cc,
@                 const void *nonce, size_t nonce_len)
@
@   Start a new message, with the provided nonce. Nonce length is between
@   0 and 20 bytes (inclusive); the nonce[] buffer is not necessarily
@   aligned.
@ =======================================================================
	.align	1
	.global	saturnin_aead_reset
	.thumb
	.thumb_func
	.type	saturnin_aead_reset, %function
saturnin_aead_reset:
	push	{r4, r5, r6, lr}
	adds	r0, #96   @ offset of ctr[] in the context
	movs	r4, r0
	movs	r6, r2    @ nonce_len

	@ Copy the nonce into the ctr[] buffer, padded.
	bl	memcpy

	@ Pad the nonce.
	adds	r0, r4, r6
	movs	r1, #0x80
	strb	r1, [r0]
	adds	r0, #1
	eors	r1, r1
	movs	r2, #31
	subs	r2, r6
	bl	memset

	@ Copy the ctr[] field to the cascade[] field; both are aligned.
	subs	r5, r4, #32
	ldm	r4!, {r0, r1, r2, r3}
	stm	r5!, {r0, r1, r2, r3}
	ldm	r4!, {r0, r1, r2, r3}
	stm	r5!, {r0, r1, r2, r3}

	@ Start the cascade by encrypting the initial ctr[] value, then
	@ XOR of the output with that block.
	movs	r0, #10
	adr	r1, .RC_10_2
	subs	r4, r5, #32
	subs	r2, r4, #64
	movs	r3, r4
	bl	saturnin_block_encrypt
	movs	r0, r4
	movs	r1, r5
	bl	xor32_aligned

	@ Set the ptr field to 0
	movs	r0, #0
	str	r0, [r5, #64]

	pop	{r4, r5, r6, pc}
	.size	saturnin_aead_reset, .-saturnin_aead_reset

@ =======================================================================
@ void saturnin_aead_aad_inject(saturnin_aead_context *cc,
@                 const void *aad, size_t aad_len)
@
@   Inject some associated authenticated data.
@ =======================================================================
	.align	1
	.global	saturnin_aead_aad_inject
	.thumb
	.thumb_func
	.type	saturnin_aead_aad_inject, %function
saturnin_aead_aad_inject:
	push	{r0, r4, r5, r6, r7, lr}   @ r0 for alignment

	movs	r4, r0            @ context
	movs	r5, r1            @ aad[]
	movs    r6, r2            @ aad_len
	ldr	r7, [r4, #160]    @ ptr

	@ If the buffer is not empty, try to complete it with fresh AAD.
	@ If the provided AAD is not sufficient, simply exit.
	cbz	r7, .Laad_inject_step2
	adds	r0, #128
	adds	r0, r7            @ &cc->buf[ptr]
	movs	r2, #32
	subs	r2, r7
	cmp	r2, r6
	bhi	.Laad_inject_early_exit
	adds	r5, r2
	subs	r6, r2
	bl	memcpy
	movs	r0, r4
	adr	r1, .RC_10_2
	bl	do_cascade_aligned
	movs	r7, #0

.Laad_inject_step2:
.Laad_inject_loop:
	cmp	r6, #31
	bls	.Laad_inject_exit

	@ Copy the next block into buf[]. Source data is not necessarily
	@ aligned, so we use memcpy().
	adds	r0, r4, #128
	movs	r1, r5
	movs	r2, #32
	bl	memcpy

	@ Continue the cascade.
	movs	r0, r4
	adr	r1, .RC_10_2
	bl	do_cascade_aligned

	@ Consider the 32 bytes of AAD consumed.
	adds	r5, #32
	subs	r6, #32
	b	.Laad_inject_loop

.Laad_inject_exit:
	@ Copy the remaining of the data into buf[].
	adds	r0, r4, #128
	movs	r1, r5
	movs	r2, r6
	bl	memcpy
	str	r6, [r4, #160]
	pop	{r0, r4, r5, r6, r7, pc}

.Laad_inject_early_exit:
	movs	r2, r6
	adds	r7, r6
	bl	memcpy
	str	r7, [r4, #160]
	pop	{r0, r4, r5, r6, r7, pc}
	.size	saturnin_aead_aad_inject, .-saturnin_aead_aad_inject

@ =======================================================================
@ void pad_buffer(void *buf)
@
@     r0   pointer to the 32-byte buffer (must be followed by ptr)
@
@   r0, r1, r2 and r3 may be altered arbitrarily.
@
@   This rountine extract the ptr value at address r4+32 (i.e. immediately
@   after the buffer to pad); this is the length of the data in the
@   buffer.
@ =======================================================================
	.align	1
	.thumb
	.thumb_func
	.type	pad_buffer, %function
pad_buffer:
	ldr	r1, [r0, #32]    @ ptr
	adds	r0, r1
	movs	r2, #0x80
	strb	r2, [r0]
	adds	r0, #1
	movs	r2, #31
	subs	r2, r1
	movs	r1, #0
	b	memset           @ tail call to memset
	.size	pad_buffer, .-pad_buffer

@ =======================================================================
@ void saturnin_aead_flip(saturnin_aead_context *cc)
@
@   Finish processing of AAD, start things for encryption/decryption.
@ =======================================================================
	.align	1
	.global	saturnin_aead_flip
	.thumb
	.thumb_func
	.type	saturnin_aead_flip, %function
saturnin_aead_flip:
	push	{r4, lr}

	movs	r4, r0            @ context
	adds	r0, #128
	bl	pad_buffer

	@ Process the final block.
	movs	r0, r4
	adr	r1, .RC_10_3
	bl	do_cascade_aligned

	@ Clear the ptr field.
	movs	r0, #0
	str	r0, [r4, #160]
	pop	{r4, pc}
	.size	saturnin_aead_flip, .-saturnin_aead_flip

@ =======================================================================
@ aead_run_partial: internal routine, special call convention
@
@     r2   buf (pointer &cc->buf[ptr])
@     r5   encrypt (0 = decrypt, -1 = encrypt)
@     r6   data
@     r3   number of bytes to process (0 <= r3 <= 31)
@
@   r0 and r1 may be altered arbitrarily.
@   r2 is modified (new r2 is the sum of old r2 and old r3).
@   r6 is modified (new r6 is the sum of old r6 and old r3).
@   r3 is set to 0.
@
@   Encrypt (if r5 == -1) or decrypt (if r5 == 0) some data.
@   The encryption/decryption is done in place. The r2 parameter
@   points to some emplacement within the buf[] field of the context
@   (not necessarily at the start). All r3 bytes can fit in the
@   remaining of that buffer. This function performs only buffer
@   processing (XOR, keeping the ciphertext bytes), but does not
@   call the block encryption or the cascade.
@ =======================================================================
	.align	1
	.thumb
	.thumb_func
	.type	aead_run_partial, %function
aead_run_partial:
	cbz	r3, .Laead_run_partial_exit
.Laead_run_partial_loop:
	ldrb	r0, [r2]     @ CTR-stream byte
	ldrb	r1, [r6]     @ input byte
	eors	r1, r0       @ output byte
	bics	r0, r5
	eors	r0, r1       @ ciphertext byte
	strb	r1, [r6]
	strb	r0, [r2]
	adds	r2, #1
	adds	r6, #1
	subs	r3, #1
	bne	.Laead_run_partial_loop
.Laead_run_partial_exit:
	bx	lr
	.size	aead_run_partial, .-aead_run_partial

@ =======================================================================
@ aead_run_incr_ctr: internal routine, special call convention
@
@     r4   pointer &cc->buf[0]
@
@   r0, r1, r2 and r3 may be altered arbitrarily.
@
@   Increment the counter value (from ctr[]), and copy it to the buf[]
@   array.
@ =======================================================================
	.align	1
	.thumb
	.thumb_func
	.type	aead_run_incr_ctr, %function
aead_run_incr_ctr:
	movs	r0, r4
	subs	r0, #32              @ &cc->ctr[0]
	ldm	r0!, {r1, r2, r3}
	adds	r0, #20
	stm	r0!, {r1, r2, r3}
	subs	r0, #32
	ldm	r0!, {r1, r2, r3}
	adds	r0, #20
	stm	r0!, {r1, r2, r3}
	subs	r0, #32
	ldm	r0!, {r1, r2}
	rev	r1, r1
	rev	r2, r2
	movs	r3, #0
	adds	r2, #1
	adcs	r1, r3
	rev	r1, r1
	rev	r2, r2
	subs	r0, #8
	stm	r0!, {r1, r2}
	adds	r0, #24
	stm	r0!, {r1, r2}
	bx	lr
	.size	aead_run_incr_ctr, .-aead_run_incr_ctr

@ =======================================================================
@ void saturnin_aead_run(saturnin_aead_context *cc, int encrypt,
@                        void *data, size_t data_len)
@
@   Encrypt (if encrypt != 0) or decrypt (if encrypt == 0) some data.
@   The encryption/decryption is done in place.
@ =======================================================================
	.align	1
	.global	saturnin_aead_run
	.thumb
	.thumb_func
	.type	saturnin_aead_run, %function
saturnin_aead_run:
	@ If there is no data, then exit early.
	cbnz	r3, .Lsaturnin_aead_run_step1
	bx	lr

.Lsaturnin_aead_run_step1:
	push	{r0, r4, r5, r6, r7, lr}    @ r0 is for stack alignment

	@ Save arguments into preserved registers.
	movs	r4, r0
	movs	r5, r1
	movs	r6, r2
	movs	r7, r3

	@ Normalize the 'encrypt' flag (-1 or 0).
	@ We use the fact that x|-x has its high bit set iff x != 0.
	rsbs	r1, r1, #0    @ negate r1
	orrs	r5, r1
	asrs	r5, r5, #31

	@ Also normalize r4 to point to the buf[] field (this keeps
	@ offsets low, and thus allows the use of smaller encodings for
	@ ldr and str opcodes).
	adds	r4, #128

	@ If there is already a partial block, try to complete it.
	ldr	r2, [r4, #32]
	cbz	r2, .Lsaturnin_aead_run_step2

	@ Compute the number of bytes to inject in the first partial run.
	rsbs	r3, r2, #32
	cmp	r3, r7
	it hi
	movhi	r3, r7

	@ Pointer &cc->buf[ptr] -> into r2.
	adds	r2, r4

	@ The aead_run_partial call will consume r3 data bytes.
	subs	r7, r3

	@ Process the r3 next bytes.
	bl	aead_run_partial

	@ r2 now points to the new &cc->buf[ptr]. From this we can
	@ infer the new value of ptr. If this is less than 31, then
	@ we are finished; we just write back the new value, and exit.
	movs	r3, r2
	subs	r3, r4
	cmp	r3, #31
	bls	.Lsaturnin_aead_run_exit

	@ We made a complete block, so we must run the cascade on it.
	movs	r0, r4
	subs	r0, #128
	adr	r1, .RC_10_4
	bl	do_cascade_aligned

.Lsaturnin_aead_run_step2:
	@ At this point, the buffer is empty. We process all full
	@ blocks.
.Lsaturnin_aead_run_loop:
	@ Consume 32 bytes; if the result is negative, then there are not
	@ as many remaining bytes, and we go to step 3.
	subs	r7, #32
	bmi	.Lsaturnin_aead_run_step3

	@ Generate next ctr block and encrypt it. We use a 64-bit counter;
	@ as per the specification, the counter is big-endian.
	bl	aead_run_incr_ctr

	movs	r0, #10         @ 10 super-rounds
	adr	r1, .RC_10_1    @ round constants
	movs	r2, r4
	subs	r2, #128        @ keybuf[]
	movs	r3, r4          @ buf[]
	bl	saturnin_block_encrypt

	@ Read data block, update it, and also copy the ciphertext to
	@ the buf[] array. The data block may be unaligned.
	movs	r3, #28
.Lsaturnin_aead_run_loop2:
	ldr	r0, [r4, r3]     @ CTR-stream word
	ldr	r1, [r6, r3]     @ input word
	eors	r1, r0           @ output word
	bics	r0, r5
	eors	r0, r1           @ ciphertext word
	str	r1, [r6, r3]     @ store back output word
	str	r0, [r4, r3]     @ store ciphertext word in buf
	subs	r3, #4
	bpl	.Lsaturnin_aead_run_loop2

	@ Apply the cascade on the full ciphertext block.
	movs	r0, r4
	subs	r0, #128
	adr	r1, .RC_10_4
	bl	do_cascade_aligned

	@ Loop for next block.
	adds	r6, #32
	b	.Lsaturnin_aead_run_loop

.Lsaturnin_aead_run_step3:
	@ At that point, there is less than a full block, and the buffer
	@ is empty. The number of remaining bytes to process is r7+32.
	adds	r7, #32
	movs	r3, r7
	beq	.Lsaturnin_aead_run_exit

	@ Prepare next block of CTR-stream
	bl	aead_run_incr_ctr
	movs	r0, #10         @ 10 super-rounds
	adr	r1, .RC_10_1    @ round constants
	movs	r2, r4
	subs	r2, #128        @ keybuf[]
	movs	r3, r4          @ buf[]
	bl	saturnin_block_encrypt

	@ Process the remaining bytes.
	movs	r2, r4
	movs	r3, r7
	bl	aead_run_partial

	@ Set r3 to the new value of cc->ptr.
	movs	r3, r7

.Lsaturnin_aead_run_exit:
	@ We get here when we are finished, with just cc->ptr to update.
	@ The new value of ptr is in r3.
	str	r3, [r4, #32]
	pop	{r0, r4, r5, r6, r7, pc}
	.size	saturnin_aead_run, .-saturnin_aead_run

@ =======================================================================
@ void saturnin_aead_get_tag(saturnin_aead_context *cc,
@                            void *tag, size_t tag_len)
@
@   Finish computation of the authentication tag, and copy it into
@   the provided buffer. The caller ensures that tag_len is at
@   most 32.
@ =======================================================================
	.align	1
	.global	saturnin_aead_get_tag
	.thumb
	.thumb_func
	.type	saturnin_aead_get_tag, %function
saturnin_aead_get_tag:
	push	{r4, r5, r6, lr}

	movs	r4, r0           @ context
	movs	r5, r1           @ tag
	movs    r6, r2           @ tag_len

	@ Pad the current buffer contents.
	adds	r0, #128         @ &cc->buf[0]
	bl	pad_buffer

	@ Final Cascade block.
	movs	r0, r4
	adr	r1, .RC_10_5
	bl	do_cascade_aligned

	@ Copy the tag value.
	movs	r0, r5
	adds	r1, r4, #64
	movs	r2, r6
	bl	memcpy

	pop	{r4, r5, r6, pc}
	.size	saturnin_aead_get_tag, .-saturnin_aead_get_tag

@ =======================================================================
@ int saturnin_aead_check_tag(saturnin_aead_context *cc,
@                              const void *tag, size_t tag_len)
@
@   Finish computation of the authentication tag, and compare it
@   with the provided value; the caller ensures that tag_len is at
@   most 32. Returned value is 1 on exact match, 0 otherwise.
@ =======================================================================
	.align	1
	.global	saturnin_aead_check_tag
	.thumb
	.thumb_func
	.type	saturnin_aead_check_tag, %function
saturnin_aead_check_tag:
	push	{r4, r5, r6, lr}

	movs	r4, r0           @ context
	movs	r5, r1           @ tag
	movs    r6, r2           @ tag_len

	@ Compute tag value into a stack buffer.
	sub	sp, sp, #32
	mov	r1, sp
	bl	saturnin_aead_get_tag

	@ Do the comparison.
	movs	r2, #0
	mov	r3, sp
.Lsaturnin_aead_check_tag_loop:
	subs	r6, #1
	bmi	.Lsaturnin_aead_check_tag_step2
	ldrb	r0, [r3, r6]
	ldrb	r1, [r5, r6]
	eors	r0, r1
	orrs	r2, r0
	b	.Lsaturnin_aead_check_tag_loop
.Lsaturnin_aead_check_tag_step2:
	adds	r2, #0xFF
	lsrs	r2, r2, #8
	movs	r0, #1
	subs	r0, r2

	add	sp, sp, #32
	pop	{r4, r5, r6, pc}
	.size	saturnin_aead_check_tag, .-saturnin_aead_check_tag

@ =======================================================================
@ Saturnin-Hash.
@
@ The context is the following structure (declared in saturnin.h):
@
@   typedef struct {
@           uint8_t state[32];
@           uint8_t buf[32];
@           size_t ptr;
@   } saturnin_hash_context;
@
@ =======================================================================

@ =======================================================================
@ void saturnin_hash_init(saturnin_hash_context *hc)
@
@   Initialize a context for a new hash computation.
@ =======================================================================
	.align	1
	.global	saturnin_hash_init
	.thumb
	.thumb_func
	.type	saturnin_hash_init, %function
saturnin_hash_init:
	movs	r3, #0
	str	r3, [r0, #64]
	movs	r1, #0
	movs	r2, #32
	b	memset      @ tail call to memset
	.size	saturnin_hash_init, .-saturnin_hash_init

@ =======================================================================
@ void hash_process_block(const uint8_t *key, const uint32_t *rc,
@                         const uint8_t *in, const uint8_t *out)
@
@   Compute: in XOR E(key, in) -> out
@
@   out[] may be the same buffer as key[].
@   The in[] and out[] buffers MUST be 32-bit aligned.
@ =======================================================================
	.align	1
	.thumb
	.thumb_func
	.type	hash_process_block, %function
hash_process_block:
	push	{r4, r5, r6, lr}
	sub	sp, sp, #64

	@ Save parameters.
	movs	r4, r1
	movs	r5, r2
	movs	r6, r3

	@ Expand key into stack buffer.
	movs	r1, r0
	mov	r0, sp
	bl	saturnin_key_expand

	@ Copy the input block into the output block. We do it
	@ manually because this is more efficient than calling memcpy().
	ldm	r5!, {r0, r1, r2, r3}
	stm	r6!, {r0, r1, r2, r3}
	ldm	r5!, {r0, r1, r2, r3}
	stm	r6!, {r0, r1, r2, r3}
	subs	r5, #32
	subs	r6, #32

	@ Apply the block encryption.
	movs	r0, #16
	movs	r1, r4
	mov	r2, sp
	movs	r3, r6
	bl	saturnin_block_encrypt

	@ XOR input block into output block.
	movs	r0, r6
	movs	r1, r5
	bl	xor32_aligned

	add	sp, sp, #64
	pop	{r4, r5, r6, pc}
	.size	hash_process_block, .-hash_process_block

@ =======================================================================
@ void saturnin_hash_update(saturnin_hash_context *hc,
@                           const void *data, size_t data_len)
@
@   Inject more bytes in the context.
@ =======================================================================
	.align	1
	.global	saturnin_hash_update
	.thumb
	.thumb_func
	.type	saturnin_hash_update, %function
saturnin_hash_update:
	push	{r0, r4, r5, r6, r7, lr}    @ r0 is for stack alignment

	@ Save parameters.
	movs	r4, r0      @ context
	movs	r5, r1      @ data
	movs	r6, r2      @ data_len

	@ Read current ptr. If non-zero, then complete the current block.
	ldr	r7, [r4, #64]
	tst	r7, r7
	beq	.Lsaturnin_hash_update_step2

	@ Copy bytes into the buffer.
	adds	r0, #32
	adds	r0, r7      @ destination: &hc->buf[ptr]
	movs	r1, r5      @ source: data
	movs	r2, #32
	subs	r2, r7
	cmp	r2, r6
	it hi
	movhi	r2, r6      @ length: min(32-ptr, data_len)
	adds	r5, r2      @ consume data (pointer)
	subs	r6, r2      @ consume data (length)
	adds	r7, r2      @ new ptr value
	bl	memcpy

	@ If still not a full block, exit.
	cmp	r7, #31
	bls	.Lsaturnin_hash_update_exit

	@ Process the full block.
	movs	r0, r4           @ key: current state[]
	adr	r1, .RC_16_7     @ round constants
	movs	r2, r4
	adds	r2, #32          @ in: buf[]
	movs	r3, r4           @ out: state[]
	bl	hash_process_block

.Lsaturnin_hash_update_step2:
	@ Process full blocks.
.Lsaturnin_hash_update_loop:
	subs	r6, #32
	bmi	.Lsaturnin_hash_update_step3

	@ Copy next data block into buf[], in order to make it aligned.
	adds	r4, #32
	ldr	r0, [r5]
	ldr	r1, [r5, #4]
	ldr	r2, [r5, #8]
	ldr	r3, [r5, #12]
	stm	r4!, {r0, r1, r2, r3}
	ldr	r0, [r5, #16]
	ldr	r1, [r5, #20]
	ldr	r2, [r5, #24]
	ldr	r3, [r5, #28]
	stm	r4!, {r0, r1, r2, r3}
	subs	r4, #64
	adds	r5, #32

	@ Apply the block encryption.
	movs	r0, r4
	adr	r1, .RC_16_7     @ round constants
	movs	r2, r4
	adds	r2, #32          @ in: buf[]
	movs	r3, r4           @ out: state[]
	bl	hash_process_block

	@ Loop for next block.
	b	.Lsaturnin_hash_update_loop

.Lsaturnin_hash_update_step3:
	@ At this point, there are fewer remaining bytes than a full
	@ block; number of remaining bytes is r6+32. We simply buffer
	@ them.
	adds	r6, #32
	movs	r0, r4
	adds	r0, #32
	movs	r1, r5
	movs	r2, r6
	bl	memcpy
	movs	r7, r6

.Lsaturnin_hash_update_exit:
	str	r7, [r4, #64]    @ Store back ptr
	pop	{r0, r4, r5, r6, r7, pc}
	.size	saturnin_hash_update, .-saturnin_hash_update

@ =======================================================================
@ void saturnin_hash_out(const saturnin_hash_context *hc, void *out)
@
@   Complete hash computation.
@ =======================================================================
	.align	1
	.global	saturnin_hash_out
	.thumb
	.thumb_func
	.type	saturnin_hash_out, %function
saturnin_hash_out:
	push	{r4, r5, r6, r7, lr}
	sub	sp, sp, #68  @ two 32-byte stack buffers + alignment

	@ Save parameters.
	movs	r6, r0       @ context
	movs	r7, r1       @ out

	@ Copy the current contents of buf[] into the lower stack buffer.
	movs	r1, r6
	adds	r1, #32
	mov	r0, sp
	ldm	r1!, {r2, r3, r4, r5}
	stm	r0!, {r2, r3, r4, r5}
	ldm	r1!, {r2, r3, r4, r5}
	stm	r0!, {r2, r3, r4, r5}
	@ Copy also the ptr field (pad_buffer expects it just after the block).
	ldr	r2, [r1]
	str	r2, [r0]

	@ Pad current buffer. This also reads the ptr field (located
	@ just after the buffer).
	mov	r0, sp
	bl	pad_buffer

	@ Process the padded block.
	@ Output is into a stack buffer (we need an aligned buffer, and
	@ we cannot modify the context).
	movs	r0, r6           @ key: current state[]
	adr	r1, .RC_16_8     @ round constants
	mov	r2, sp           @ in: padded input
	mov	r3, sp
	adds	r3, #32          @ output: upper stack buffer
	bl	hash_process_block

	@ Copy the process block into the output.
	movs	r0, r7
	mov	r1, sp
	adds	r1, #32
	movs	r2, #32

	add	sp, sp, #68
	pop	{r4, r5, r6, r7, lr}
	b	memcpy           @ tail call
	.size	saturnin_hash_out, .-saturnin_hash_out
