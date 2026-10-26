#!/usr/bin/env python3
"""Validate privacy declarations and offline policy in the built app or IPA."""
import plistlib
import sys
import zipfile
from pathlib import Path


def validate(read):
    manifest = plistlib.loads(read('PrivacyInfo.xcprivacy'))
    if manifest.get('NSPrivacyTracking') is not False:
        raise ValueError('Unexpected tracking declaration')
    if manifest.get('NSPrivacyTrackingDomains') != [] or manifest.get('NSPrivacyCollectedDataTypes') != []:
        raise ValueError('Privacy declarations differ from the reviewed offline app')
    expected = [{'NSPrivacyAccessedAPIType': 'NSPrivacyAccessedAPICategoryUserDefaults',
                 'NSPrivacyAccessedAPITypeReasons': ['CA92.1']}]
    if manifest.get('NSPrivacyAccessedAPITypes') != expected:
        raise ValueError('Missing or unexpected required-reason API declarations')
    policy = read('PrivacyPolicy.txt').decode('utf-8')
    if 'Pluki privacy policy' not in policy or 'add-only Photos permission' not in policy:
        raise ValueError('Missing offline privacy policy')


def main():
    path = Path(sys.argv[1])
    if path.suffix.lower() == '.ipa':
        with zipfile.ZipFile(path) as archive:
            roots = [n[:-len('Info.plist')] for n in archive.namelist()
                     if n.startswith('Payload/') and n.count('/') == 2 and n.endswith('.app/Info.plist')]
            if len(roots) != 1:
                raise ValueError('Expected one app in IPA')
            validate(lambda name: archive.read(roots[0] + name))
    else:
        validate(lambda name: (path / name).read_bytes())
    print('Bundled privacy manifest, app-only UserDefaults reason and offline policy verified.')


if __name__ == '__main__':
    main()
