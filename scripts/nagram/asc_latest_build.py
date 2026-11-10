import base64
import json
import os
import sys
import time
import urllib.error
import urllib.request

from cryptography.hazmat.primitives.asymmetric.ec import ECDSA
from cryptography.hazmat.primitives.asymmetric.utils import decode_dss_signature
from cryptography.hazmat.primitives.hashes import SHA256
from cryptography.hazmat.primitives.serialization import load_pem_private_key


def b64(data: bytes) -> bytes:
    return base64.urlsafe_b64encode(data).rstrip(b"=")


def token(key_id: str, issuer: str, key_path: str) -> str:
    key = load_pem_private_key(open(key_path, "rb").read(), password=None)
    header = b64(json.dumps({"alg": "ES256", "kid": key_id, "typ": "JWT"}).encode())
    now = int(time.time())
    payload = b64(json.dumps({"iss": issuer, "iat": now, "exp": now + 600, "aud": "appstoreconnect-v1"}).encode())
    message = header + b"." + payload
    r, s = decode_dss_signature(key.sign(message, ECDSA(SHA256())))
    return (message + b"." + b64(r.to_bytes(32, "big") + s.to_bytes(32, "big"))).decode()


def fetch(path: str, bearer: str) -> list:
    request = urllib.request.Request(
        "https://api.appstoreconnect.apple.com" + path,
        headers={"Authorization": f"Bearer {bearer}"},
    )
    try:
        with urllib.request.urlopen(request) as response:
            return json.load(response).get("data", [])
    except urllib.error.HTTPError as error:
        sys.exit(f"App Store Connect returned {error.code} for {path}: {error.read().decode(errors='replace')}")


def main() -> None:
    key_id = os.environ["ASC_KEY_ID"]
    bearer = token(key_id, os.environ["ASC_ISSUER_ID"], os.environ["ASC_KEY_PATH"])
    app_id = os.environ["APPSTORE_ID"]
    uploads = fetch(f"/v1/apps/{app_id}/buildUploads?fields[buildUploads]=cfBundleVersion&limit=200", bearer)
    builds = fetch(f"/v1/builds?filter[app]={app_id}&sort=-uploadedDate&limit=200", bearer)
    versions = [str(item.get("attributes", {}).get("cfBundleVersion", "")) for item in uploads]
    versions += [str(item.get("attributes", {}).get("version", "")) for item in builds]
    numbers = [int(version) for version in versions if version.isdigit()]
    if not numbers:
        sys.exit("App Store Connect returned no numeric build or upload versions")
    print(max(numbers))


if __name__ == "__main__":
    main()
