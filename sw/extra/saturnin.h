#ifndef saturnin_h__
#define saturnin_h__

#include <stddef.h>
#include <stdint.h>

/*
 * Saturnin-CTR-Cascade context. This is allocated by the caller in any
 * emplacement (stack, heap, static data...). Precise semantics of the
 * context fields are not part of the API.
 */
typedef struct {
	uint32_t keybuf[16];
	uint8_t cascade[32];
	uint8_t ctr[32];
	uint8_t buf[32];
	size_t ptr;
} saturnin_aead_context;

/*
 * Initialize an AEAD context with a given key. The caller must make
 * sure to provide only a valid key length. Saturnin expects a key of
 * exactly 32 bytes.
 */
void saturnin_aead_init(saturnin_aead_context *cc,
	const void *key, size_t key_len);

/*
 * Reset a context for a new AEAD computation, with the key which was
 * set with the last saturnin_aead_init() call on that context.
 *
 * The caller must provide a valid nonce. Saturnin accepts all nonce
 * lengths from 0 to 20 bytes (inclusive).
 */
void saturnin_aead_reset(saturnin_aead_context *cc,
	const void *nonce, size_t nonce_len);

/*
 * Inject some associated authenticated data (AAD), to be part of the
 * authentication tag processing. This call must occur after
 * saturnin_aead_reset(), but before saturnin_aead_flip(). The AAD may
 * be injected in several calls with chunks of arbitrary length. If
 * there is no AAD to inject, it is not necessary to call this function.
 */
void saturnin_aead_aad_inject(saturnin_aead_context *cc,
	const void *aad, size_t aad_len);

/*
 * Finish processing of the AAD, and start encryption or decryption of
 * data.
 */
void saturnin_aead_flip(saturnin_aead_context *cc);

/*
 * Encrypt (if encrypt != 0) or decrypt (if encrypt == 0) some data.
 * This call should occur after saturnin_aead_flip(). Processing is
 * performed in-place (the output data replaces the input data). The
 * message data may be processed in several calls with chunks of
 * arbitrary length. If there is no message data (i.e. the AEAD is used
 * only as a MAC over the AAD), then it is not necessary to call this
 * function.
 *
 * If a single message is processed in several chunks, then all calls
 * should agree on the 'encrypt' flag.
 */
void saturnin_aead_run(saturnin_aead_context *cc,
	int encrypt, void *data, size_t data_len);

/*
 * Finish processing of a message, producing an authentication tag of the
 * specified length. The caller is responsible for asking only for valid
 * tag lengths. Saturnin can produce tags of 0 to 32 bytes (inclusive).
 *
 * (Of course, empty or short tags provide no or weak security against
 * forgeries.)
 *
 * Once this function has been called, the processing of the message is
 * finished (in particular, calling this function again immediately after
 * will not necessarily yield the same tag value). Such a context can
 * be reset (with saturnin_aead_reset()) to process another message with
 * the same key, or reinitialized (with saturnin_aead_init()) to process
 * another message with a different key.
 */
void saturnin_aead_get_tag(saturnin_aead_context *cc,
	void *tag, size_t tag_len);

/*
 * This is a variant of saturnin_aead_get_tag(); it internally calls
 * saturnin_aead_get_tag(). However, instead of returning the computed
 * tag, it compares the tag with the provided value. Returned value is
 * 1 if the tags match, 0 otherwise. This is intended to be used when
 * an encrypted message is received. If a value of 0 is returned, then
 * the message and/or the tag is altered, and the message contents
 * shall be discarded.
 */
int saturnin_aead_check_tag(saturnin_aead_context *cc,
	const void *tag, size_t tag_len);

/*
 * Saturnin-Hash context. This is allocated by the caller in any
 * emplacement (stack, heap, static data...). Precise semantics of the
 * context fields are not part of the API.
 */
typedef struct {
	uint8_t state[32];
	uint8_t buf[32];
	size_t ptr;
} saturnin_hash_context;

/*
 * Initialize a context for a new hash computation.
 */
void saturnin_hash_init(saturnin_hash_context *hc);

/*
 * Process some bytes with the hash function. The complete message to
 * be hashed can be processed in several calls with arbitrary chunk
 * length.
 */
void saturnin_hash_update(saturnin_hash_context *hc,
	const void *data, size_t data_len);

/*
 * Finalize the hash computation and write the output into the out[]
 * buffer. The hash output length depends on the implemented function
 * (Saturnin-Hash produces 32 bytes).
 *
 * The context is NOT modified by this call; this allows obtained
 * "partial hashes" (hash value of all data injected so far) without
 * interrupting a running hash computation.
 */
void saturnin_hash_out(const saturnin_hash_context *hc,
	void *out);

#endif
