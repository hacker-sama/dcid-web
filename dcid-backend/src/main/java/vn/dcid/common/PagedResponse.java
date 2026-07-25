package vn.dcid.common;

import java.util.List;

public record PagedResponse<T>(
        List<T> items,
        int page,
        int size,
        long total
) {

    public static <T> PagedResponse<T> of(List<T> items, int page, int size, long total) {
        return new PagedResponse<>(items, page, size, total);
    }
}
