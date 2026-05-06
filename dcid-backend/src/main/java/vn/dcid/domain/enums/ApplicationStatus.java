package vn.dcid.domain.enums;

import java.util.Set;

public enum ApplicationStatus {
    DRAFT,
    SUBMITTED,
    IN_REVIEW,
    PENDING_SUPPLEMENT,
    APPROVED,
    REJECTED,
    WITHDRAWN;

    private static final Set<ApplicationStatus> TERMINAL_STATUSES = Set.of(APPROVED, REJECTED, WITHDRAWN);

    public boolean isTerminal() {
        return TERMINAL_STATUSES.contains(this);
    }

    public boolean canTransitionTo(ApplicationStatus next) {
        return TRANSITIONS.getOrDefault(this, Set.of()).contains(next);
    }

    private static final java.util.Map<ApplicationStatus, Set<ApplicationStatus>> TRANSITIONS = java.util.Map.of(
            DRAFT, Set.of(SUBMITTED, WITHDRAWN),
            SUBMITTED, Set.of(IN_REVIEW, WITHDRAWN),
            IN_REVIEW, Set.of(PENDING_SUPPLEMENT, APPROVED, REJECTED),
            PENDING_SUPPLEMENT, Set.of(SUBMITTED, WITHDRAWN),
            APPROVED, Set.of(),
            REJECTED, Set.of(),
            WITHDRAWN, Set.of()
    );
}
