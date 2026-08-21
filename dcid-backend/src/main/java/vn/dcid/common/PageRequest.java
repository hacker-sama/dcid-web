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
        if (size <= 0 || size > 500) {
            size = 100;
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
            String[] parts = sort.split(",");
            String property = parts[0].trim();
            org.springframework.data.domain.Sort.Direction direction =
                    (parts.length > 1 && "desc".equalsIgnoreCase(parts[1].trim()))
                            ? org.springframework.data.domain.Sort.Direction.DESC
                            : org.springframework.data.domain.Sort.Direction.ASC;
            return org.springframework.data.domain.PageRequest.of(page, size,
                    org.springframework.data.domain.Sort.by(direction, property));
        }
        return org.springframework.data.domain.PageRequest.of(page, size,
                org.springframework.data.domain.Sort.by(org.springframework.data.domain.Sort.Direction.DESC, "createdAt"));
    }
}
