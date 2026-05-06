package vn.dcid.common;

public record PageRequest(
        int page,
        int size,
        String sort
) {

    public PageRequest {
        if (page < 0) {
            page = 0;
        }
        if (size <= 0 || size > 100) {
            size = 20;
        }
    }

    public static PageRequest of(int page, int size) {
        return new PageRequest(page, size, null);
    }

    public static PageRequest of(int page, int size, String sort) {
        return new PageRequest(page, size, sort);
    }

    public org.springframework.data.domain.PageRequest toSpringPageRequest() {
        if (sort != null && !sort.isBlank()) {
            return org.springframework.data.domain.PageRequest.of(page, size,
                    org.springframework.data.domain.Sort.by(sort));
        }
        return org.springframework.data.domain.PageRequest.of(page, size);
    }
}
