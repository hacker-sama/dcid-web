"""GET /ai/status/{task_id} — Truy vấn trạng thái Celery task.

Endpoint này cho phép polling tiến độ xử lý ingest document.
State flow: PENDING → PROCESSING_OCR → PROCESSING_EMBED → PROCESSING_INDEX → SUCCESS | FAILURE

Lưu ý: Đây là endpoint phụ trợ — luồng chính nên dùng callback push (BE nhận
POST /api/internal/ingest-status tại mỗi bước). Endpoint này hữu ích cho
debug, monitoring và fallback khi BE cần chủ động kiểm tra.
"""

import logging

from celery.result import AsyncResult
from fastapi import APIRouter, Depends

from app.schemas import TaskStatusResponse
from app.security import require_internal_token

logger = logging.getLogger("dcid-ai.api.status")

router = APIRouter(prefix="/ai", tags=["status"], dependencies=[Depends(require_internal_token)])


@router.get("/status/{task_id}", response_model=TaskStatusResponse)
def get_task_status(task_id: str) -> TaskStatusResponse:
    """Truy vấn trạng thái Celery task theo task_id.

    Args:
        task_id: Celery task ID trả về từ POST /ai/ingest response.taskId

    Returns:
        TaskStatusResponse với state và thông tin chi tiết bước đang xử lý.

    States:
        - PENDING:           Task chưa được xử lý (đang trong queue).
        - PROCESSING_OCR:    Đang OCR trang PDF qua ai-ocr service.
        - PROCESSING_EMBED:  Đang chunk text và tạo vector embedding.
        - PROCESSING_INDEX:  Đang upsert vectors vào Qdrant.
        - SUCCESS:           Hoàn tất — versionId đã sẵn sàng để query.
        - FAILURE:           Lỗi — xem trường `error` để biết nguyên nhân.
    """
    result = AsyncResult(task_id)
    state = result.state
    info = result.info

    # Parse info tùy theo kiểu dữ liệu Celery trả về
    step: str | None = None
    error: str | None = None
    info_dict: dict | None = None

    if isinstance(info, dict):
        step = info.get("step")
        error = info.get("error")
        info_dict = {k: v for k, v in info.items() if k not in ("step", "error")}
    elif isinstance(info, Exception):
        # FAILURE state: info là exception object
        error = str(info)
        state = "FAILURE"
    elif info is not None:
        info_dict = {"raw": str(info)}

    logger.debug("Status query: taskId=%s state=%s", task_id, state)

    return TaskStatusResponse(
        taskId=task_id,
        state=state,
        step=step,
        info=info_dict or None,
        error=error,
    )
