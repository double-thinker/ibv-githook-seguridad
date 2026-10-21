"""Mini app de ejemplo: descarga una URL y muestra el código de estado."""
import sys

import requests


def main() -> int:
    url = sys.argv[1] if len(sys.argv) > 1 else "https://www.ibv.org"
    resp = requests.get(url, timeout=10)
    print(f"{url} -> HTTP {resp.status_code}, {len(resp.content)} bytes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
