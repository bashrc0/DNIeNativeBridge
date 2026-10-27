#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import <CommonCrypto/CommonDigest.h>
#include "config.h"
#include "RSACompatibility.h"
#include "libopensc/sc-ossl-compat.h"

#define REQUIRE(value) do { if (!(value)) { fprintf(stderr,"Failed at line %d: %s\n",__LINE__,#value); return 1; } } while (0)

int main(void) { @autoreleasepool {
    sc_context_t context = {0};
    ossl3ctx_t crypto = {0};
    crypto.libctx = OSSL_LIB_CTX_new();
    REQUIRE(crypto.libctx != NULL);
    crypto.defprov = OSSL_PROVIDER_load(crypto.libctx,"default");
    REQUIRE(crypto.defprov != NULL);
    context.ossl3ctx = &crypto;
    const unsigned long currentDNIe = SC_ALGORITHM_RSA_HASH_NONE | SC_ALGORITHM_RSA_PAD_PKCS1;
    unsigned long software = 0, card = 0;
    REQUIRE(dnieRSAEncodingStatus(&context, SC_ALGORITHM_RSA_PAD_PKCS1_TYPE_01 | SC_ALGORITHM_RSA_HASH_SHA256, currentDNIe, &software, &card) == SC_SUCCESS);
    REQUIRE(dnieRSAEncodingStatus(&context, dniePSSFlags(SC_ALGORITHM_RSA_HASH_SHA256), currentDNIe, &software, &card) == SC_ERROR_NOT_SUPPORTED);
    REQUIRE(dniePSSFlags(0) == UINT_MAX);
    REQUIRE(dnieRSAEncodingStatus(&context, UINT_MAX, currentDNIe, &software, &card) == SC_ERROR_NOT_SUPPORTED);

    NSDictionary *parameters = @{(__bridge id)kSecAttrKeyType: (__bridge id)kSecAttrKeyTypeRSA,
                                 (__bridge id)kSecAttrKeySizeInBits: @2048,
                                 (__bridge id)kSecAttrIsPermanent: @NO};
    CFErrorRef error = NULL;
    SecKeyRef privateKey = SecKeyCreateRandomKey((__bridge CFDictionaryRef)parameters, &error);
    REQUIRE(privateKey != NULL);
    SecKeyRef publicKey = SecKeyCopyPublicKey(privateKey);
    REQUIRE(publicKey != NULL);
    NSData *message = [@"DNIeNativeBridge offline RSA-PSS interoperability test" dataUsingEncoding:NSUTF8StringEncoding];
    const unsigned int hashes[] = {SC_ALGORITHM_RSA_HASH_SHA256, SC_ALGORITHM_RSA_HASH_SHA384, SC_ALGORITHM_RSA_HASH_SHA512};
    const SecKeyAlgorithm algorithms[] = {kSecKeyAlgorithmRSASignatureMessagePSSSHA256, kSecKeyAlgorithmRSASignatureMessagePSSSHA384, kSecKeyAlgorithmRSASignatureMessagePSSSHA512};
    for (NSUInteger i=0;i<3;i++) {
        unsigned char digest[CC_SHA512_DIGEST_LENGTH]; size_t length;
        if (i==0) { CC_SHA256(message.bytes,(CC_LONG)message.length,digest); length=CC_SHA256_DIGEST_LENGTH; }
        else if (i==1) { CC_SHA384(message.bytes,(CC_LONG)message.length,digest); length=CC_SHA384_DIGEST_LENGTH; }
        else { CC_SHA512(message.bytes,(CC_LONG)message.length,digest); length=CC_SHA512_DIGEST_LENGTH; }
        REQUIRE(dnieRSAEncodingStatus(&context, dniePSSFlags(hashes[i]), SC_ALGORITHM_RSA_RAW, &software, &card) == SC_SUCCESS);
        REQUIRE(card == SC_ALGORITHM_RSA_PAD_NONE);
        unsigned char encoded[256]; size_t encodedLength=sizeof(encoded);
        REQUIRE(sc_pkcs1_encode(&context,software,digest,length,encoded,&encodedLength,2048,NULL) == SC_SUCCESS);
        REQUIRE(encodedLength == 256);
        NSData *block=[NSData dataWithBytes:encoded length:encodedLength];
        CFDataRef signature=SecKeyCreateSignature(privateKey,kSecKeyAlgorithmRSASignatureRaw,(__bridge CFDataRef)block,&error);
        REQUIRE(signature != NULL);
        REQUIRE(SecKeyVerifySignature(publicKey,algorithms[i],(__bridge CFDataRef)message,signature,&error));
        NSData *changed=[@"a different message" dataUsingEncoding:NSUTF8StringEncoding];
        CFErrorRef negativeError=NULL;
        REQUIRE(!SecKeyVerifySignature(publicKey,algorithms[i],(__bridge CFDataRef)changed,signature,&negativeError));
        if (negativeError) CFRelease(negativeError);
        CFRelease(signature);
    }
    CFRelease(publicKey); CFRelease(privateKey); if(error) CFRelease(error);
    OSSL_PROVIDER_unload(crypto.defprov); OSSL_LIB_CTX_free(crypto.libctx);
    puts("PASS: real DNIe capability guard and OpenSC PSS encoding verified independently with Security (SHA-256/384/512).");
    return 0;
} }
