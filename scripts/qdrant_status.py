"""Check Qdrant readiness and the kcn_chunks collection count."""

from __future__ import annotations

import argparse
import json
import sys
from urllib.error import URLError
from urllib.request import urlopen


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", default="http://localhost:6333")
    parser.add_argument("--collection", default="kcn_chunks")
    args = parser.parse_args()
    url = f"{args.url.rstrip('/')}/collections/{args.collection}"
    try:
        with urlopen(url, timeout=5) as response:  # noqa: S310 - local operator tool
            payload = json.load(response)
    except URLError as exc:
        print(f"Qdrant is unavailable at {args.url}: {exc}", file=sys.stderr)
        return 1

    result = payload.get("result", {})
    print(f"Qdrant status: {result.get('status', 'unknown')}")
    print(f"Collection: {args.collection}")
    print(f"Points: {result.get('points_count', 0)}")
    print(f"Indexed vectors: {result.get('indexed_vectors_count', 0)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
