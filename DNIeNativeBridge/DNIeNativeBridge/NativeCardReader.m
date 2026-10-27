#import "NativeCardReader.h"
#import "NativeKeySelection.h"
@import Security;

#include "config.h"
#include "libopensc/opensc.h"
#include "libopensc/pkcs15.h"
#include "eac/eac.h"

static dispatch_queue_t readerQueue(void) {
    static dispatch_queue_t queue;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ queue = dispatch_queue_create("es.local.DNIeNativeBridge.operations", DISPATCH_QUEUE_SERIAL); });
    return queue;
}

static NSArray *publishedKeys(NSArray<NSString *> *tokenIDs, BOOL authenticationOnly, OSStatus *status) {
    NSMutableArray *keys = [NSMutableArray array];
    *status = errSecItemNotFound;
    for (NSString *tokenID in tokenIDs) {
        if (![tokenID hasPrefix:@"es.local.DNIeNativeBridge."]) continue;
        NSDictionary *query = @{
            (__bridge id)kSecClass: (__bridge id)kSecClassKey,
            (__bridge id)kSecAttrKeyClass: (__bridge id)kSecAttrKeyClassPrivate,
            (__bridge id)kSecAttrTokenID: tokenID,
            (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitAll,
            (__bridge id)kSecReturnRef: @YES,
            (__bridge id)kSecReturnAttributes: @YES,
            (__bridge id)kSecUseAuthenticationUI: (__bridge id)kSecUseAuthenticationUIFail
        };
        CFTypeRef result = NULL;
        OSStatus found = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
        if (found != errSecSuccess || !result) { if (result) CFRelease(result); continue; }
        NSArray *items = CFGetTypeID(result) == CFArrayGetTypeID() ? (__bridge NSArray *)result : @[(__bridge id)result];
        for (id item in items) {
            if (![item isKindOfClass:NSDictionary.class]) continue;
            // The item's label belongs to SecItem attributes, not SecKeyCopyAttributes.
            id key = item[(__bridge id)kSecValueRef];
            if (!key || CFGetTypeID((__bridge CFTypeRef)key) != SecKeyGetTypeID()) continue;
            NSDictionary *attributes = CFBridgingRelease(SecKeyCopyAttributes((__bridge SecKeyRef)key));
            if (![attributes[(__bridge id)kSecAttrTokenID] isEqual:tokenID]) continue;
            if (authenticationOnly && !DNIeIsAuthenticationLabel(item[(__bridge id)kSecAttrLabel])) continue;
            [keys addObject:key];
        }
        CFRelease(result);
        *status = errSecSuccess;
    }
    return keys;
}

static NSInteger publishedIdentityCount(NSArray<NSString *> *tokenIDs) {
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassIdentity,
        (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitAll,
        (__bridge id)kSecReturnRef: @YES,
        (__bridge id)kSecUseAuthenticationUI: (__bridge id)kSecUseAuthenticationUIFail
    };
    CFTypeRef found = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &found);
    if (status != errSecSuccess || !found) { if (found) CFRelease(found); return 0; }
    NSArray *items = CFGetTypeID(found) == CFArrayGetTypeID() ? (__bridge NSArray *)found : @[(__bridge id)found];
    NSInteger count = 0;
    for (id item in items) {
        if (CFGetTypeID((__bridge CFTypeRef)item) != SecIdentityGetTypeID()) continue;
        SecKeyRef key = NULL;
        if (SecIdentityCopyPrivateKey((__bridge SecIdentityRef)item, &key) != errSecSuccess || !key) continue;
        NSDictionary *attributes = CFBridgingRelease(SecKeyCopyAttributes(key));
        NSString *tokenID = attributes[(__bridge id)kSecAttrTokenID];
        if ([tokenID hasPrefix:@"es.local.DNIeNativeBridge."] && [tokenIDs containsObject:tokenID]) count++;
        CFRelease(key);
    }
    CFRelease(found);
    return count;
}

static void reportProgress(void (^progress)(NSString *), NSString *stage) {
    dispatch_async(dispatch_get_main_queue(), ^{ progress(stage); });
}

static NSInteger countPublishedItems(CFStringRef itemClass, NSString *tokenID, OSStatus *status) {
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)itemClass,
        (__bridge id)kSecAttrTokenID: tokenID,
        (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitAll,
        (__bridge id)kSecReturnRef: @YES,
        (__bridge id)kSecUseAuthenticationUI: (__bridge id)kSecUseAuthenticationUIFail
    };
    CFTypeRef items = NULL;
    *status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &items);
    NSInteger count = 0;
    if (*status == errSecSuccess && items) {
        count = CFGetTypeID(items) == CFArrayGetTypeID() ? CFArrayGetCount(items) : 1;
    }
    if (items) CFRelease(items);
    return count;
}

static void inspectIdentities(NSString *tokenID, NSInteger *count, NSInteger *sha256Count, OSStatus *status) {
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassKey,
        (__bridge id)kSecAttrKeyClass: (__bridge id)kSecAttrKeyClassPrivate,
        (__bridge id)kSecAttrTokenID: tokenID,
        (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitAll,
        (__bridge id)kSecReturnRef: @YES,
        (__bridge id)kSecUseAuthenticationUI: (__bridge id)kSecUseAuthenticationUIFail
    };
    CFTypeRef found = NULL;
    *count = 0;
    *sha256Count = 0;
    *status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &found);
    if (*status != errSecSuccess || !found) return;
    NSArray *keys = CFGetTypeID(found) == CFArrayGetTypeID()
        ? (__bridge NSArray *)found : @[(__bridge id)found];
    for (id item in keys) {
        SecKeyRef key = (__bridge SecKeyRef)item;
        NSDictionary *attributes = CFBridgingRelease(SecKeyCopyAttributes(key));
        NSString *actualTokenID = attributes[(__bridge id)kSecAttrTokenID];
        if ([actualTokenID isEqualToString:tokenID]) {
            (*count)++;
            if (SecKeyIsAlgorithmSupported(key, kSecKeyOperationTypeSign,
                                          kSecKeyAlgorithmRSASignatureDigestPKCS1v15SHA256)) (*sha256Count)++;
        }
    }
    CFRelease(found);
}

static BOOL acquireSession(TKSmartCard *smartCard, NSError **outError) {
    dispatch_semaphore_t ready = dispatch_semaphore_create(0);
    NSLock *gate = [[NSLock alloc] init];
    __block BOOL completed = NO, expired = NO, granted = NO;
    __block NSError *sessionError = nil;
    [smartCard beginSessionWithReply:^(BOOL success, NSError *error) {
        [gate lock];
        if (expired) {
            [gate unlock];
            if (success) [smartCard endSession];
            return;
        }
        granted = success;
        sessionError = error;
        completed = YES;
        [gate unlock];
        dispatch_semaphore_signal(ready);
    }];
    if (dispatch_semaphore_wait(ready, dispatch_time(DISPATCH_TIME_NOW, 12 * NSEC_PER_SEC)) != 0) {
        [gate lock];
        if (!completed) expired = YES;
        BOOL timedOut = expired;
        [gate unlock];
        if (timedOut) {
            if (outError) *outError = [NSError errorWithDomain:@"DNIeNativeBridge" code:1 userInfo:@{
                NSLocalizedDescriptionKey: @"El lector no concede una sesión exclusiva en 12 segundos. Puede existir otra sesión pendiente; retira y vuelve a insertar el DNIe."}];
            return NO;
        }
    }
    if (!granted && outError) *outError = sessionError;
    return granted;
}

@implementation NativeCardReader

+ (void)inventoryForTokenIDs:(NSArray<NSString *> *)tokenIDs completion:(void (^)(NSString *))completion {
    dispatch_async(readerQueue(), ^{
        NSMutableArray<NSString *> *lines = [NSMutableArray array];
        for (NSString *tokenID in tokenIDs) {
            OSStatus identityStatus;
            NSInteger identities, sha256Count;
            inspectIdentities(tokenID, &identities, &sha256Count, &identityStatus);
            NSString *source = [[tokenID componentsSeparatedByString:@":"] firstObject];
            [lines addObject:[NSString stringWithFormat:@"%@: %ld claves privadas publicadas; %ld admiten firma RSA-SHA256 (estado %d).",
                              source, (long)identities, (long)sha256Count, (int)identityStatus]];
        }
        NSString *summary = lines.count ? [lines componentsJoinedByString:@"\n"] : @"No hay tokens de tarjeta inteligente publicados en esta sesión.";
        dispatch_async(dispatch_get_main_queue(), ^{ completion(summary); });
    });
}

+ (void)compatibilityForTokenIDs:(NSArray<NSString *> *)tokenIDs completion:(void (^)(NSDictionary<NSString *, id> *))completion {
    dispatch_async(readerQueue(), ^{
        OSStatus status;
        NSArray *keys = publishedKeys(tokenIDs, NO, &status);
        NSMutableDictionary *report = [@{@"keys": @(keys.count), @"identities": @(publishedIdentityCount(tokenIDs)), @"status": @(status)} mutableCopy];
        NSArray *names = @[@"pkcs1SHA256", @"pkcs1SHA384", @"pkcs1SHA512", @"pssSHA256", @"pssSHA384", @"pssSHA512", @"rawRSA"];
        NSArray *algorithms = @[(__bridge id)kSecKeyAlgorithmRSASignatureMessagePKCS1v15SHA256,
                                (__bridge id)kSecKeyAlgorithmRSASignatureMessagePKCS1v15SHA384,
                                (__bridge id)kSecKeyAlgorithmRSASignatureMessagePKCS1v15SHA512,
                                (__bridge id)kSecKeyAlgorithmRSASignatureMessagePSSSHA256,
                                (__bridge id)kSecKeyAlgorithmRSASignatureMessagePSSSHA384,
                                (__bridge id)kSecKeyAlgorithmRSASignatureMessagePSSSHA512,
                                (__bridge id)kSecKeyAlgorithmRSASignatureRaw];
        for (NSUInteger i = 0; i < names.count; i++) {
            NSInteger supported = 0;
            for (id item in keys)
                if (SecKeyIsAlgorithmSupported((__bridge SecKeyRef)item, kSecKeyOperationTypeSign, (__bridge SecKeyAlgorithm)algorithms[i])) supported++;
            report[names[i]] = @(supported);
        }
        dispatch_async(dispatch_get_main_queue(), ^{ completion(report); });
    });
}

+ (void)testAuthenticationForTokenIDs:(NSArray<NSString *> *)tokenIDs pss:(BOOL)pss completion:(void (^)(NSDictionary<NSString *, id> *))completion {
    dispatch_async(readerQueue(), ^{
        NSDictionary *result = nil;
        OSStatus status;
        NSArray *keys = publishedKeys(tokenIDs, YES, &status);
        // An ambiguous selection must never fall back to the document-signing key.
        id authenticationKey = keys.count == 1 ? keys.firstObject : nil;
        SecKeyAlgorithm algorithm = pss ? kSecKeyAlgorithmRSASignatureMessagePSSSHA256 : kSecKeyAlgorithmRSASignatureMessagePKCS1v15SHA256;
        if (!authenticationKey) {
            result = @{@"ok": @NO, @"message": @"No se encuentra la clave de autenticación del DNIe. Inserta la tarjeta y comprueba las identidades."};
        } else if (!SecKeyIsAlgorithmSupported((__bridge SecKeyRef)authenticationKey, kSecKeyOperationTypeSign, algorithm)) {
            result = @{@"ok": @NO, @"message": @"El proveedor actual no admite el algoritmo seleccionado. No se ha solicitado el PIN ni se ha enviado una operación de firma a la tarjeta."};
        } else {
            uint8_t random[32];
            status = SecRandomCopyBytes(kSecRandomDefault, sizeof(random), random);
            if (status != errSecSuccess) {
                result = @{@"ok": @NO, @"message": @"No se ha podido generar el reto aleatorio de la prueba."};
            } else {
                NSMutableData *challenge = [[@"DNIeNativeBridge: prueba local de autenticación; sin trámite ni documento.\n" dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
                [challenge appendBytes:random length:sizeof(random)];
                CFErrorRef signError = NULL;
                SecKeyRef key = (__bridge SecKeyRef)authenticationKey;
                CFDataRef signature = SecKeyCreateSignature(key, algorithm, (__bridge CFDataRef)challenge, &signError);
                SecKeyRef publicKey = SecKeyCopyPublicKey(key);
                CFErrorRef verifyError = NULL;
                BOOL valid = signature && publicKey && SecKeyVerifySignature(publicKey, algorithm, (__bridge CFDataRef)challenge, signature, &verifyError);
                result = @{@"ok": @(valid), @"message": valid ? @"Firma de autenticación generada en el DNIe y verificada con su clave pública. No se han guardado el reto, la firma ni el PIN." : @"La firma de prueba no se ha completado o no se ha podido verificar. No se repite automáticamente; comprueba el diálogo local y la tarjeta."};
                if (signature) CFRelease(signature);
                if (publicKey) CFRelease(publicKey);
                if (signError) CFRelease(signError);
                if (verifyError) CFRelease(verifyError);
                memset(random, 0, sizeof(random));
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{ completion(result); });
    });
}

+ (NSDictionary<NSString *, id> *)readPublicCertificatesFromSlot:(TKSmartCardSlot *)slot
                                                      progress:(void (^)(NSString *))progress {
    sc_context_t *ctx = NULL;
    sc_card_t *card = NULL;
    sc_pkcs15_card_t *p15card = NULL;
    struct sc_pkcs15_object *objects[32] = {0};
    sc_context_param_t parameters = {0};
    NSString *stage = @"Crear contexto OpenSC";
    NSString *cardName = @"Tarjeta";
    int r = SC_ERROR_INTERNAL;
    int certificates = 0, identities = 0, failedCertificates = 0;
    TKSmartCard *smartCard = [slot makeSmartCard];
    if (!smartCard) {
        return @{@"ok": @NO, @"message": @"No se pudo abrir la tarjeta del lector."};
    }

    reportProgress(progress, @"Solicitar acceso exclusivo al lector");
    NSError *sessionError = nil;
    if (!acquireSession(smartCard, &sessionError)) {
        return @{@"ok": @NO, @"stage": @"Acceso exclusivo", @"message":
                     sessionError.localizedDescription ?: @"CryptoTokenKit no concedió acceso a la tarjeta."};
    }

    NSString *resources = [[[[NSBundle mainBundle] builtInPlugInsPath]
        stringByAppendingPathComponent:@"DNIeTokenExtension.appex"]
        stringByAppendingPathComponent:@"Contents/Resources"];
    NSString *configuration = [resources stringByAppendingPathComponent:@"opensc.conf"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:configuration]) {
        setenv("OPENSC_CONF", configuration.fileSystemRepresentation, 1);
    }
    parameters.ver = 1;
    parameters.app_name = "cryptotokenkit";
    reportProgress(progress, stage);
    r = sc_context_create(&ctx, &parameters);
    if (r < 0 || !ctx) goto cleanup;
    // Do not collect APDU traces or personal certificate data in this test.
    ctx->debug = 0;
    EAC_set_cvc_default_dir(resources.fileSystemRepresentation);
    EAC_set_x509_default_dir(resources.fileSystemRepresentation);

    stage = @"Abrir lector CryptoTokenKit";
    reportProgress(progress, stage);
    r = sc_ctx_use_reader(ctx, (__bridge void *)slot, (__bridge void *)smartCard);
    if (r < 0) goto cleanup;

    stage = @"Reconocer tarjeta con OpenSC";
    reportProgress(progress, stage);
    r = sc_connect_card(sc_ctx_get_reader(ctx, sc_ctx_get_reader_count(ctx) - 1), &card);
    if (r < 0) goto cleanup;
    if (card->name) cardName = [NSString stringWithUTF8String:card->name];

    stage = @"Abrir perfil PKCS#15";
    reportProgress(progress, [NSString stringWithFormat:@"%@: %@", cardName, stage]);
    struct sc_app_info *application = sc_pkcs15_get_application_by_type(card, "generic");
    r = sc_pkcs15_bind(card, application ? &application->aid : NULL, &p15card);
    if (r < 0) goto cleanup;
    p15card->opts.use_pin_cache = 0;
    p15card->opts.use_file_cache = SC_PKCS15_OPTS_CACHE_NO_FILES;

    stage = @"Enumerar certificados públicos";
    reportProgress(progress, stage);
    r = sc_pkcs15_get_objects(p15card, SC_PKCS15_TYPE_CERT_X509, objects, 32);
    if (r < 0) goto cleanup;
    int objectCount = r;
    for (int i = 0; i < objectCount; i++) {
        struct sc_pkcs15_cert_info *info = objects[i]->data;
        struct sc_pkcs15_cert *certificate = NULL;
        struct sc_pkcs15_object *key = NULL;
        // The flag controls file caching; this call never verifies a PIN.
        int privateObject = objects[i]->flags & SC_PKCS15_CO_FLAG_PRIVATE;
        int readResult = sc_pkcs15_read_certificate(p15card, info, privateObject, &certificate);
        if (readResult < 0 || !certificate) {
            failedCertificates++;
            continue;
        }
        NSData *der = [NSData dataWithBytes:certificate->data.value length:certificate->data.len];
        SecCertificateRef parsed = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)der);
        if (parsed) {
            certificates++;
            if (sc_pkcs15_find_prkey_by_id(p15card, &info->id, &key) == SC_SUCCESS) identities++;
            CFRelease(parsed);
        } else {
            failedCertificates++;
        }
        sc_pkcs15_free_certificate(certificate);
    }
    r = certificates > 0 ? SC_SUCCESS : SC_ERROR_OBJECT_NOT_FOUND;
    stage = @"Leer y validar certificados DER";

cleanup:
    if (p15card) sc_pkcs15_card_free(p15card);
    if (card) sc_disconnect_card(card);
    if (ctx) sc_release_context(ctx);
    [smartCard endSession];
    if (r < 0) {
        NSString *reason = [NSString stringWithUTF8String:sc_strerror(r)];
        return @{@"ok": @NO, @"code": @(r), @"stage": stage,
                 @"message": [NSString stringWithFormat:@"%@: %@ (%d). %@. Certificados leídos: %d; errores: %d.",
                              stage, reason, r, cardName, certificates, failedCertificates]};
    }
    return @{@"ok": @YES, @"certificates": @(certificates), @"identities": @(identities),
             @"message": [NSString stringWithFormat:@"%@: %d certificados DER válidos; %d asociados a claves privadas. Lectura realizada sin PIN y sin guardar certificados.",
                          cardName, certificates, identities]};
}

+ (void)readSlot:(TKSmartCardSlot *)slot progress:(void (^)(NSString *))progress
      completion:(void (^)(NSDictionary<NSString *, id> *))completion {
    static dispatch_queue_t queue;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ queue = dispatch_queue_create("es.local.DNIeNativeBridge.reader", DISPATCH_QUEUE_SERIAL); });
    dispatch_async(queue, ^{
        @autoreleasepool {
            NSDictionary *result = [self readPublicCertificatesFromSlot:slot progress:progress];
            dispatch_async(dispatch_get_main_queue(), ^{ completion(result); });
        }
    });
}

@end
