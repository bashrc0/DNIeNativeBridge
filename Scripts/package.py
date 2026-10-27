#!/usr/bin/env python3
"""Package an existing signed Intel build without installing or registering it."""
import argparse
from pathlib import Path
import plistlib
import shutil
import subprocess
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]

def run(*args):
    subprocess.run([str(arg) for arg in args], check=True)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--app', type=Path, required=True)
    parser.add_argument('--output', type=Path, default=ROOT / 'dist')
    args = parser.parse_args()
    app = args.app.resolve()
    info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
    if info.get('CFBundleIdentifier') != 'es.local.DNIeNativeBridge':
        parser.error('Expected a DNIeNativeBridge app bundle.')
    run('codesign', '--verify', '--deep', '--strict', app)
    version = info['CFBundleShortVersionString']
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    destination = output / ('DNIeNativeBridge-' + version + '-Intel.pkg')
    if destination.exists():
        parser.error('The destination package already exists. Choose a fresh --output directory.')
    with tempfile.TemporaryDirectory(prefix='dnie-package-') as tmp:
        work = Path(tmp)
        payload = work / 'root'
        installed = payload / 'Applications/DNIeNativeBridge.app'
        shutil.copytree(app, installed, symlinks=True)
        components = work / 'components.plist'
        run('pkgbuild', '--analyze', '--root', payload, components)
        settings = plistlib.loads(components.read_bytes())
        for component in settings:
            component.update(BundleIsRelocatable=False, BundleOverwriteAction='upgrade')
        components.write_bytes(plistlib.dumps(settings))
        component_pkg = work / 'DNIeNativeBridge-component.pkg'
        run('pkgbuild', '--root', payload, '--component-plist', components,
            '--scripts', ROOT / 'Install/FullInstallerScripts',
            '--identifier', 'es.local.DNIeNativeBridge.installer', '--version', version,
            '--install-location', '/', component_pkg)
        tree = ET.Element('installer-gui-script', minSpecVersion='2')
        ET.SubElement(tree, 'title').text = 'DNIeNativeBridge ' + version + ' — Intel'
        ET.SubElement(tree, 'options', customize='never', hostArchitectures='x86_64')
        ET.SubElement(tree, 'domains', enable_localSystem='true', enable_currentUserHome='false', enable_anywhere='false')
        check = ET.SubElement(tree, 'volume-check')
        versions = ET.SubElement(check, 'allowed-os-versions')
        ET.SubElement(versions, 'os-version', min='15.5')
        outline = ET.SubElement(tree, 'choices-outline')
        ET.SubElement(outline, 'line', choice='main')
        choice = ET.SubElement(tree, 'choice', id='main', visible='false')
        ET.SubElement(choice, 'pkg-ref', id='es.local.DNIeNativeBridge.installer')
        ref = ET.SubElement(tree, 'pkg-ref', id='es.local.DNIeNativeBridge.installer', version=version, onConclusion='none')
        ref.text = '#DNIeNativeBridge-component.pkg'
        distribution = work / 'Distribution.xml'
        ET.ElementTree(tree).write(distribution, encoding='utf-8', xml_declaration=True)
        run('productbuild', '--distribution', distribution, '--package-path', work, destination)
    print('Created:', destination)
    print('The installer is not Developer ID Installer signed or notarized by this script.')

if __name__ == '__main__':
    main()
