#import <Foundation/Foundation.h>
#import <CryptoTokenKit/CryptoTokenKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Inventory and certificate reading never request a PIN. A signature test
/// explicitly initiated by the user may request it through the system UI.
@interface NativeCardReader : NSObject
+ (void)inventoryForTokenIDs:(NSArray<NSString *> *)tokenIDs
                  completion:(void (^)(NSString *summary))completion
    NS_SWIFT_NAME(inventory(tokenIDs:completion:));
+ (void)compatibilityForTokenIDs:(NSArray<NSString *> *)tokenIDs
                    completion:(void (^)(NSDictionary<NSString *, id> *result))completion
    NS_SWIFT_NAME(compatibility(tokenIDs:completion:));
+ (void)testAuthenticationForTokenIDs:(NSArray<NSString *> *)tokenIDs
                                 pss:(BOOL)pss
                          completion:(void (^)(NSDictionary<NSString *, id> *result))completion
    NS_SWIFT_NAME(testAuthentication(tokenIDs:pss:completion:));
+ (void)readSlot:(TKSmartCardSlot *)slot
        progress:(void (^)(NSString *stage))progress
      completion:(void (^)(NSDictionary<NSString *, id> *result))completion
    NS_SWIFT_NAME(read(slot:progress:completion:));
@end

NS_ASSUME_NONNULL_END
