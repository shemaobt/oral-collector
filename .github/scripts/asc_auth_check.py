"""Mint the same ES256 JWT xcodebuild uses and call the App Store Connect API.
Reads APPSTORE_API_KEY_ID, APPSTORE_ISSUER_ID, API_KEY_PATH from the environment.
Prints only the HTTP status (no secret values). Temporary CI diagnostic."""
import os, time, json, base64, urllib.request, urllib.error

kid = os.environ["APPSTORE_API_KEY_ID"]
iss = os.environ["APPSTORE_ISSUER_ID"]
keypath = os.environ["API_KEY_PATH"]
now = int(time.time())
payload = {"iss": iss, "iat": now, "exp": now + 600, "aud": "appstoreconnect-v1"}


def b64u(b: bytes) -> bytes:
    return base64.urlsafe_b64encode(b).rstrip(b"=")


token = None
try:
    import jwt as pyjwt
    with open(keypath) as f:
        token = pyjwt.encode(payload, f.read(), algorithm="ES256", headers={"kid": kid})
    if isinstance(token, bytes):
        token = token.decode()
except Exception:
    from cryptography.hazmat.primitives.serialization import load_pem_private_key
    from cryptography.hazmat.primitives.asymmetric import ec
    from cryptography.hazmat.primitives import hashes
    from cryptography.hazmat.primitives.asymmetric.utils import decode_dss_signature
    with open(keypath, "rb") as f:
        key = load_pem_private_key(f.read(), password=None)
    header = {"alg": "ES256", "kid": kid, "typ": "JWT"}
    si = b64u(json.dumps(header, separators=(",", ":")).encode()) + b"." + b64u(json.dumps(payload, separators=(",", ":")).encode())
    der = key.sign(si, ec.ECDSA(hashes.SHA256()))
    r, s = decode_dss_signature(der)
    token = (si + b"." + b64u(r.to_bytes(32, "big") + s.to_bytes(32, "big"))).decode()

req = urllib.request.Request(
    "https://api.appstoreconnect.apple.com/v1/apps?limit=1",
    headers={"Authorization": "Bearer " + token},
)
try:
    resp = urllib.request.urlopen(req, timeout=30)
    print("ASC API HTTP", resp.status, "-> CI CREDENTIALS VALID (key + id + issuer all good in CI)")
except urllib.error.HTTPError as e:
    verdict = "CI AUTH FAILED" if e.code in (401, 403) else "unexpected"
    print("ASC API HTTP", e.code, "->", verdict)
    print(e.read()[:300].decode("utf-8", "replace"))
