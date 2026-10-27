#!/usr/bin/env python3
"""Build the Intel host and CryptoTokenKit extension from the published sources."""
import argparse
import json
from pathlib import Path
import plistlib
import shutil
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[1]

def run(*args):
    subprocess.run([str(arg) for arg in args], check=True)

def write_plist(path, values):
    path.write_bytes(plistlib.dumps(values))

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--identity', default='-', help='codesign identity; default is ad hoc')
    parser.add_argument('--output', type=Path, default=ROOT / 'build', help='build directory')
    parser.add_argument('--cache', type=Path, help='optional compiler module cache directory')
    args = parser.parse_args()
    version = json.loads((ROOT / 'Version.json').read_text())
    output = args.output.resolve()
    app = output / 'DNIeNativeBridge.app'
    if app.exists():
        parser.error('The output app already exists. Choose a fresh --output directory.')
    output.mkdir(parents=True, exist_ok=True)
    cache = (args.cache or output / 'cache').resolve()
    cache.mkdir(parents=True, exist_ok=True)
    sdk = subprocess.check_output(['xcrun', '--show-sdk-path'], text=True).strip()
    target = 'x86_64-apple-macosx15.5'
    project = ROOT / 'DNIeNativeBridge'
    host = project / 'DNIeNativeBridge'
    token = project / 'DNIeTokenExtension'
    deps = ROOT / 'ThirdParty/BuildInputs'
    includes = [deps / p for p in ('OpenSC', 'OpenSC/src', 'include/openpace', 'include/openssl')]
    libraries = [deps / 'lib' / n for n in ('libopensc.a', 'libeac.a', 'libcrypto.a')]
    for library in libraries:
        if not library.is_file():
            parser.error('Missing dependency: ' + str(library))
    resources = app / 'Contents/Resources'
    binary = app / 'Contents/MacOS/DNIeNativeBridge'
    extension = app / 'Contents/PlugIns/DNIeTokenExtension.appex'
    for directory in (resources, binary.parent, extension / 'Contents/MacOS', extension / 'Contents/Resources'):
        directory.mkdir(parents=True, exist_ok=True)
    # Wrap the approved PNG catalog in an ICNS container; no image regeneration.
    catalog = host / 'Assets.xcassets/AppIcon.appiconset'
    entries = [('icp4','icon_16x16.png'), ('icp5','icon_32x32.png'),
               ('icp6','icon_32x32@2x.png'), ('ic07','icon_128x128.png'),
               ('ic08','icon_256x256.png'), ('ic09','icon_512x512.png'),
               ('ic10','icon_512x512@2x.png'), ('ic11','icon_16x16@2x.png'),
               ('ic12','icon_32x32@2x.png'), ('ic13','icon_128x128@2x.png'),
               ('ic14','icon_256x256@2x.png')]
    chunks = []
    for kind, filename in entries:
        data = (catalog / filename).read_bytes()
        chunks.append(kind.encode('ascii') + struct.pack('>I', len(data) + 8) + data)
    payload = b''.join(chunks)
    (resources / 'AppIcon.icns').write_bytes(b'icns' + struct.pack('>I', len(payload) + 8) + payload)
    common = ['-target', target, '-isysroot', sdk, '-fobjc-arc', '-fmodules', '-O2',
              '-fmodules-cache-path=' + str(cache / 'clang')]
    common += ['-I' + str(path) for path in includes]
    native = output / 'NativeCardReader.o'
    run('xcrun', 'clang', *common, '-c', host / 'NativeCardReader.m', '-o', native)
    run('xcrun', 'clang', *common, '-fapplication-extension',
        *(token / filename for filename in ('TokenDriver.m', 'Token.m', 'TokenSession.m')),
        *libraries, '-framework', 'Foundation', '-framework', 'CryptoTokenKit',
        '-framework', 'Security', '-lz', '-Wl,-e,_NSExtensionMain',
        '-o', extension / 'Contents/MacOS/DNIeTokenExtension')
    run('xcrun', 'swiftc', '-parse-as-library', '-O', '-target', target, '-sdk', sdk,
        '-module-name', 'DNIeNativeBridge', '-module-cache-path', cache / 'swift',
        '-import-objc-header', host / 'DNIeNativeBridge-Bridging-Header.h',
        *sorted(host.glob('*.swift')),
        native, *libraries, '-framework', 'SwiftUI', '-framework', 'AppKit',
        '-framework', 'CryptoTokenKit', '-framework', 'Security', '-lz', '-o', binary)
    token_info = plistlib.loads((token / 'Info.plist').read_bytes())
    token_info.update(CFBundleExecutable='DNIeTokenExtension', CFBundleName='DNIeTokenExtension',
                      CFBundleDisplayName='DNIe Native Bridge',
                      CFBundleIdentifier='es.local.DNIeNativeBridge.DNIeTokenExtension',
                      CFBundlePackageType='XPC!', CFBundleInfoDictionaryVersion='6.0',
                      CFBundleShortVersionString=version['extension']['version'], CFBundleVersion=version['extension']['build'],
                      CFBundleSupportedPlatforms=['MacOSX'], LSMinimumSystemVersion='15.5')
    write_plist(extension / 'Contents/Info.plist', token_info)
    for path in (token / 'Resources').iterdir():
        if path.is_file():
            shutil.copy2(path, extension / 'Contents/Resources' / path.name)
    write_plist(app / 'Contents/Info.plist', dict(
        CFBundleDevelopmentRegion='en', CFBundleExecutable='DNIeNativeBridge',
        CFBundleName='DNIeNativeBridge', CFBundleIdentifier='es.local.DNIeNativeBridge',
        CFBundlePackageType='APPL', CFBundleInfoDictionaryVersion='6.0',
        CFBundleShortVersionString=version['host']['version'], CFBundleVersion=version['host']['build'],
        CFBundleSupportedPlatforms=['MacOSX'], LSMinimumSystemVersion='15.5',
        CFBundleIconFile='AppIcon.icns', NSHumanReadableCopyright='Creado por RPastor y GPT'))
    run('codesign', '--force', '--sign', args.identity, '--entitlements',
        token / 'DNIeTokenExtension.entitlements', extension)
    run('codesign', '--force', '--sign', args.identity, '--entitlements',
        host / 'DNIeNativeBridge.entitlements', app)
    run('codesign', '--verify', '--deep', '--strict', app)
    print('Built and verified:', app)
    if args.identity == '-':
        print('Ad hoc build only. Configure your own signing identity before testing CryptoTokenKit.')

if __name__ == '__main__':
    main()
