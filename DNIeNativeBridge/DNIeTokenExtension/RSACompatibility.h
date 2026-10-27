/* DNIeNativeBridge · RPastor, with GPT assistance. GPL-3.0-or-later. */
#ifndef DNIE_RSA_COMPATIBILITY_H
#define DNIE_RSA_COMPATIBILITY_H
#include <limits.h>
#include "libopensc/opensc.h"
#include "libopensc/internal.h"

/* Security's RSA-PSS algorithms use MGF1 with the same hash and a salt
 * whose length is the digest length, matching OpenSC's default encoding. */
static inline unsigned int dniePSSFlags(unsigned int hash) {
    unsigned int mgf;
    switch (hash) {
        case SC_ALGORITHM_RSA_HASH_SHA1: mgf = SC_ALGORITHM_MGF1_SHA1; break;
        case SC_ALGORITHM_RSA_HASH_SHA224: mgf = SC_ALGORITHM_MGF1_SHA224; break;
        case SC_ALGORITHM_RSA_HASH_SHA256: mgf = SC_ALGORITHM_MGF1_SHA256; break;
        case SC_ALGORITHM_RSA_HASH_SHA384: mgf = SC_ALGORITHM_MGF1_SHA384; break;
        case SC_ALGORITHM_RSA_HASH_SHA512: mgf = SC_ALGORITHM_MGF1_SHA512; break;
        default: return UINT_MAX;
    }
    return SC_ALGORITHM_RSA_PAD_PSS | hash | mgf;
}

/* Never infer raw RSA/PSS support from the presence of an RSA certificate.
 * OpenSC must confirm that the actual card/driver can perform the operation. */
static inline int dnieRSAEncodingStatus(sc_context_t *ctx, unsigned int flags,
                                       unsigned long capabilities,
                                       unsigned long *softwareFlags,
                                       unsigned long *cardFlags) {
    if (flags == UINT_MAX) return SC_ERROR_NOT_SUPPORTED;
    return sc_get_encoding_flags(ctx, flags, capabilities, softwareFlags, cardFlags);
}
#endif
