import argparse
import json
from pathlib import Path
import subprocess
import tempfile


root = Path(__file__).resolve().parents[3]
parser = argparse.ArgumentParser()
parser.add_argument('--signal-kit', type=Path, default=root / 'submodules/telegram-ios/submodules/SSignalKit')
args = parser.parse_args()
signal_kit = args.signal_kit.resolve()

source = (root / 'packages/ChatHistoryModel/Sources/ChatHistoryModel/ChatLiveTranslateContext.swift').read_text()
start = source.index('public func chatTranslationState(')
end = source.index('\n}\n', start) + len('\n}')
fixture = Path(__file__).with_name('LanguageSwitchTests.swift').read_text()
fixture = fixture.replace('__CHAT_TRANSLATION_STATE__', source[start:end].removeprefix('public '))

with tempfile.TemporaryDirectory(prefix='chat-translation-language-') as directory:
    path = Path(directory)
    (path / 'Package.swift').write_text(f'''// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "LanguageSwitchTests",
    dependencies: [.package(name: "SSignalKit", path: {json.dumps(str(signal_kit))})],
    targets: [.executableTarget(name: "LanguageSwitchTests", dependencies: [
        .product(name: "SwiftSignalKit", package: "SSignalKit")
    ])]
)
''')
    source_dir = path / 'Sources/LanguageSwitchTests'
    source_dir.mkdir(parents=True)
    (source_dir / 'main.swift').write_text(fixture)
    subprocess.run(['xcrun', 'swift', 'run', '--package-path', str(path)], check=True)
