"""One-time, idempotent migration from ChromaDB to Qdrant.

Run this while the old Chroma container is still reachable on localhost:8001
and the new Qdrant container is reachable on localhost:6333.
"""

from __future__ import annotations

import argparse
import sys
from uuid import NAMESPACE_URL, uuid5


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--chroma-host", default="localhost")
    parser.add_argument("--chroma-port", type=int, default=8001)
    parser.add_argument("--qdrant-host", default="localhost")
    parser.add_argument("--qdrant-port", type=int, default=6333)
    parser.add_argument("--collection", default="kcn_chunks")
    parser.add_argument("--vector-size", type=int, default=384)
    parser.add_argument("--batch-size", type=int, default=128)
    return parser.parse_args()


def point_id(old_id: str, metadata: dict) -> str:
    version_id = metadata.get("version_id")
    page_no = metadata.get("page_no")
    chunk_index = metadata.get("chunk_index")
    key = (
        f"dcid:{version_id}:{page_no}:{chunk_index}"
        if version_id is not None and page_no is not None and chunk_index is not None
        else f"dcid:legacy:{old_id}"
    )
    return str(uuid5(NAMESPACE_URL, key))


def main() -> int:
    args = parse_args()
    try:
        import chromadb
        from qdrant_client import QdrantClient, models
    except ImportError as exc:
        print(
            "Missing migration dependency. Install temporarily with: "
            "pip install chromadb 'qdrant-client>=1.15,<1.17'",
            file=sys.stderr,
        )
        print(exc, file=sys.stderr)
        return 2

    chroma = chromadb.HttpClient(host=args.chroma_host, port=args.chroma_port)
    source = chroma.get_collection(args.collection)
    qdrant = QdrantClient(host=args.qdrant_host, port=args.qdrant_port, timeout=60)

    if not qdrant.collection_exists(args.collection):
        qdrant.create_collection(
            collection_name=args.collection,
            vectors_config=models.VectorParams(
                size=args.vector_size,
                distance=models.Distance.COSINE,
                on_disk=True,
            ),
            hnsw_config=models.HnswConfigDiff(on_disk=True),
            on_disk_payload=True,
        )

    for field in ("version_id", "document_id", "machineCode"):
        try:
            qdrant.create_payload_index(
                collection_name=args.collection,
                field_name=field,
                field_schema=models.PayloadSchemaType.KEYWORD,
                wait=True,
            )
        except Exception:
            pass

    source_count = source.count()
    migrated = 0
    for offset in range(0, source_count, args.batch_size):
        batch = source.get(
            limit=args.batch_size,
            offset=offset,
            include=["documents", "metadatas", "embeddings"],
        )
        points = []
        for old_id, document, metadata, embedding in zip(
            batch.get("ids", []),
            batch.get("documents", []),
            batch.get("metadatas", []),
            batch.get("embeddings", []),
        ):
            vector = embedding.tolist() if hasattr(embedding, "tolist") else list(embedding)
            if len(vector) != args.vector_size:
                raise ValueError(
                    f"Chunk {old_id} has dimension {len(vector)}, expected {args.vector_size}"
                )
            payload = dict(metadata or {})
            if "machine_code" in payload and "machineCode" not in payload:
                payload["machineCode"] = payload["machine_code"]
            payload["text"] = document or ""
            payload["chunk_id"] = old_id
            points.append(
                models.PointStruct(
                    id=point_id(old_id, payload),
                    vector=vector,
                    payload=payload,
                )
            )

        if points:
            qdrant.upsert(
                collection_name=args.collection,
                points=points,
                wait=True,
            )
            migrated += len(points)
            print(f"Migrated {migrated}/{source_count} chunks")

    target_count = qdrant.count(
        collection_name=args.collection,
        exact=True,
    ).count
    print(f"Chroma source: {source_count} chunks")
    print(f"Qdrant target: {target_count} chunks")
    if target_count < source_count:
        print("Migration verification failed: Qdrant has fewer chunks", file=sys.stderr)
        return 1
    print("Migration completed and verified.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
