from __future__ import annotations
import base64, hashlib, hmac, os, time


SECRET = os.getenv("GISAM_QR_SECRET", os.getenv("GISAM_JWT_SECRET", "dev-only-change-me"))


def create_invite(user_id: str, ttl_seconds: int = 300) -> str:
    exp = int(time.time()) + max(30, min(ttl_seconds, 3600))
    payload = f"{user_id}|{exp}".encode()
    sig = hmac.new(SECRET.encode(), payload, hashlib.sha256).digest()[:16]
    return base64.urlsafe_b64encode(payload + b"|" + sig).decode().rstrip("=")


def consume_invite(token: str) -> tuple[str, int] | None:
    try:
        raw = base64.urlsafe_b64decode(token + "=" * (-len(token) % 4))
        user, exp_s, sig = raw.split(b"|", 2)
        payload = b"|".join((user, exp_s))
        expected = hmac.new(SECRET.encode(), payload, hashlib.sha256).digest()[:16]
        if not hmac.compare_digest(sig, expected):
            return None
        exp = int(exp_s)
        if exp < int(time.time()):
            return None
        return user.decode(), exp
    except Exception:
        return None
