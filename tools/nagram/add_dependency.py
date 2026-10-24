"""Add a local package dependency (default NagramCore) to packages/<Name>/Package.swift.

Handles both manifest styles in this repository: the `deps` tuple list, and
explicit `.package(...)` / `.product(...)` entries next to SwiftSignalKit.
"""
import pathlib
import sys


def main():
    if len(sys.argv) < 2:
        sys.exit("usage: add_dependency.py <PackageName>... [--dep NagramCore]")
    args = sys.argv[1:]
    dep = "NagramCore"
    if "--dep" in args:
        i = args.index("--dep")
        dep = args[i + 1]
        del args[i:i + 2]
    root = pathlib.Path(__file__).resolve().parents[2] / "packages"
    for name in args:
        path = root / name / "Package.swift"
        text = path.read_text()
        if f'"{dep}"' in text:
            print(f"{name}: already depends on {dep}")
            continue
        tuple_anchor = "let deps: [(String, String)] = [\n"
        if tuple_anchor in text:
            text = text.replace(tuple_anchor, tuple_anchor + f'    ("{dep}", "../{dep}"),\n', 1)
        else:
            package_anchor = '.package(name: "SSignalKit", path: "../../submodules/telegram-ios/submodules/SSignalKit"),'
            product_anchor = '.product(name: "SwiftSignalKit", package: "SSignalKit", condition: nil),'
            if product_anchor not in text and '.product(name: "SwiftSignalKit", package: "SSignalKit"),' in text:
                product_anchor = '.product(name: "SwiftSignalKit", package: "SSignalKit"),'
            if package_anchor not in text or product_anchor not in text:
                sys.exit(f"{name}: no anchor found, edit the manifest by hand")
            text = text.replace(package_anchor, package_anchor + f'\n        .package(name: "{dep}", path: "../{dep}"),', 1)
            text = text.replace(product_anchor, product_anchor + f'\n    .product(name: "{dep}", package: "{dep}", condition: nil),')
        path.write_text(text)
        print(f"{name}: added {dep}")


main()
