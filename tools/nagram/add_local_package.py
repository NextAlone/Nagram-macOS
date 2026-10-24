"""Link a local Swift package under packages/ to the Telegram app target.

Mirrors how the existing packages are wired: a folder reference in the
Packages group, a product dependency and a Frameworks build file, each
inserted next to the GroupsInCommonUI entries.
"""
import hashlib
import pathlib
import sys

ANCHOR = "GroupsInCommonUI"


def new_id(seed):
    return hashlib.sha1(seed.encode()).hexdigest()[:24].upper()


def main():
    if len(sys.argv) != 3:
        sys.exit("usage: add_local_package.py <project.pbxproj> <PackageName>")
    path = pathlib.Path(sys.argv[1])
    name = sys.argv[2]
    text = path.read_text()
    if f"path = packages/{name};" in text:
        print(f"{name} is already linked")
        return
    lines = text.split("\n")
    build_file = new_id(f"{name}-buildfile")
    file_ref = new_id(f"{name}-fileref")
    product = new_id(f"{name}-product")
    out = []
    inserted = set()
    for line in lines:
        out.append(line)
        stripped = line.strip()
        if f"/* {ANCHOR} in Frameworks */ = {{isa = PBXBuildFile;" in line:
            out.append(f"\t\t{build_file} /* {name} in Frameworks */ = {{isa = PBXBuildFile; productRef = {product} /* {name} */; }};")
            inserted.add("buildfile")
        elif f"/* {ANCHOR} */ = {{isa = PBXFileReference;" in line:
            out.append(f"\t\t{file_ref} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = folder; name = {name}; path = packages/{name}; sourceTree = \"<group>\"; }};")
            inserted.add("fileref")
        elif stripped == f"{line.split('/*')[0].strip()} /* {ANCHOR} in Frameworks */," and "phase" not in inserted:
            out.append(f"\t\t\t\t{build_file} /* {name} in Frameworks */,")
            inserted.add("phase")
        elif stripped.endswith(f"/* {ANCHOR} */,"):
            ident = stripped.split()[0]
            if "fileref-id" not in inserted and ident == text.split(f" /* {ANCHOR} */ = {{isa = PBXFileReference;")[0].split()[-1]:
                out.append(f"\t\t\t\t{file_ref} /* {name} */,")
                inserted.add("fileref-id")
            elif "product-id" not in inserted:
                out.append(f"\t\t\t\t{product} /* {name} */,")
                inserted.add("product-id")
        elif stripped.endswith(f"/* {ANCHOR} */ = {{") and "productdep" not in inserted:
            pass
    text = "\n".join(out)
    marker = f"/* {ANCHOR} */ = {{\n\t\t\tisa = XCSwiftPackageProductDependency;"
    head, sep, tail = text.partition(marker)
    if not sep:
        sys.exit("product dependency anchor not found")
    start = head.rfind("\n") + 1
    block = f"\t\t{product} /* {name} */ = {{\n\t\t\tisa = XCSwiftPackageProductDependency;\n\t\t\tproductName = {name};\n\t\t}};\n"
    text = head[:start] + block + head[start:] + sep + tail
    inserted.add("productdep")
    expected = {"buildfile", "fileref", "phase", "fileref-id", "product-id", "productdep"}
    if inserted != expected:
        sys.exit(f"incomplete insertion: missing {expected - inserted}")
    path.write_text(text)
    print(f"linked {name}")


main()
