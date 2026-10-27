/* DNIeNativeBridge · RPastor, with GPT assistance. GPL-3.0-or-later. */
#import <Foundation/Foundation.h>

// The DNIe provider labels its certificate/key items CertAutenticacion and
// CertFirmaDigital. Match the leading provider label, never the owner's name.
static inline BOOL DNIeIsAuthenticationLabel(id label) {
    if (![label isKindOfClass:NSString.class]) return NO;
    NSString *normalized = [label stringByFoldingWithOptions:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch locale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    return [normalized isEqualToString:@"certautenticacion"] || [normalized hasPrefix:@"certautenticacion ("];
}
