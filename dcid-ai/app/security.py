"""Xác thực nội bộ BE↔AI bằng header X-Internal-Token (API-CONTRACT.md §0.3)."""

import hmac
from typing import Annotated

from fastapi import Depends, Header, HTTPException, status

from app.config import Settings, get_settings

INTERNAL_TOKEN_HEADER = "X-Internal-Token"


def require_internal_token(
    settings: Annotated[Settings, Depends(get_settings)],
    x_internal_token: Annotated[str | None, Header(alias=INTERNAL_TOKEN_HEADER)] = None,
) -> None:
    """Dependency: 401 nếu thiếu hoặc sai token (so sánh constant-time)."""
    if x_internal_token is None or not hmac.compare_digest(
        x_internal_token, settings.ai_internal_token
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid X-Internal-Token",
        )
