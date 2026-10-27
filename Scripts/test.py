#!/usr/bin/env python3
"""Offline checks: no smart-card access, no PIN and no persistent test keys."""
from pathlib import Path
import subprocess
import argparse

ROOT=Path(__file__).resolve().parents[1]
def run(*args): subprocess.run([str(x) for x in args],check=True)
def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,default=ROOT/'build/tests')
    args=parser.parse_args(); output=args.output.resolve();output.mkdir(parents=True,exist_ok=True)
    deps=ROOT/'ThirdParty/BuildInputs'
    includes=[deps/'OpenSC',deps/'OpenSC/src',deps/'include/openssl',ROOT/'DNIeNativeBridge/DNIeTokenExtension']
    sdk=subprocess.check_output(['xcrun','--show-sdk-path'],text=True).strip()
    run('xcrun','clang','-fobjc-arc','-fmodules','-target','x86_64-apple-macosx15.5','-isysroot',sdk,
        '-fmodules-cache-path='+str(output/'clang-cache'),*[ '-I'+str(p) for p in includes],
        ROOT/'Tests/RSACompatibilityTests.m',deps/'lib/libopensc.a',deps/'lib/libeac.a',deps/'lib/libcrypto.a',
        '-framework','Foundation','-framework','CryptoTokenKit','-framework','Security','-lz','-o',output/'rsa-tests')
    run(output/'rsa-tests')
    run('xcrun','clang','-fobjc-arc','-fmodules','-target','x86_64-apple-macosx15.5','-isysroot',sdk,
        '-fmodules-cache-path='+str(output/'clang-cache'),
        '-I'+str(ROOT/'DNIeNativeBridge/DNIeNativeBridge'), ROOT/'Tests/NativeKeySelectionTests.m',
        '-framework','Foundation','-o',output/'selection-tests')
    run(output/'selection-tests')
    run('xcrun','swiftc','-parse-as-library','-target','x86_64-apple-macosx15.5','-sdk',sdk,
        '-module-cache-path',output/'swift-cache',ROOT/'DNIeNativeBridge/DNIeNativeBridge/SafariChoiceSupport.swift',
        ROOT/'Tests/SafariChoiceSupportTests.swift','-o',output/'safari-tests')
    run(output/'safari-tests')
if __name__=='__main__':main()
