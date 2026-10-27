#import <Foundation/Foundation.h>
#import "NativeKeySelection.h"
#define REQUIRE(value) do { if (!(value)) { fprintf(stderr,"Failed at line %d\n",__LINE__); return 1; } } while (0)
int main(void) { @autoreleasepool {
    REQUIRE(DNIeIsAuthenticationLabel(@"CertAutenticacion"));
    REQUIRE(DNIeIsAuthenticationLabel(@"CertAutenticacion (AUTENTICACIÓN)"));
    REQUIRE(DNIeIsAuthenticationLabel(@"CERTAUTENTICACIÓN (persona de prueba)"));
    REQUIRE(!DNIeIsAuthenticationLabel(nil));
    REQUIRE(!DNIeIsAuthenticationLabel(@[]));
    REQUIRE(!DNIeIsAuthenticationLabel(@"CertFirmaDigital (AUTENTICACION)"));
    REQUIRE(!DNIeIsAuthenticationLabel(@"CertAutenticacionOtra"));
    REQUIRE(!DNIeIsAuthenticationLabel(@"FNMT (AUTENTICACION)"));
    puts("PASS: authentication provider label selected; document-signing, FNMT and ambiguous labels rejected.");
    return 0;
} }
