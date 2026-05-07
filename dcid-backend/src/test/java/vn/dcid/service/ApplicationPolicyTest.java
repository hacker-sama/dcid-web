package vn.dcid.service;

import org.junit.jupiter.api.Test;
import vn.dcid.domain.enums.ApplicationStatus;

import static org.junit.jupiter.api.Assertions.*;

class ApplicationPolicyTest {

    @Test
    void testCanTransitionFromDraft() {
        assertTrue(ApplicationStatus.DRAFT.canTransitionTo(ApplicationStatus.SUBMITTED));
        assertTrue(ApplicationStatus.DRAFT.canTransitionTo(ApplicationStatus.WITHDRAWN));
        assertFalse(ApplicationStatus.DRAFT.canTransitionTo(ApplicationStatus.IN_REVIEW));
        assertFalse(ApplicationStatus.DRAFT.canTransitionTo(ApplicationStatus.APPROVED));
    }

    @Test
    void testCanTransitionFromSubmitted() {
        assertTrue(ApplicationStatus.SUBMITTED.canTransitionTo(ApplicationStatus.IN_REVIEW));
        assertTrue(ApplicationStatus.SUBMITTED.canTransitionTo(ApplicationStatus.WITHDRAWN));
        assertFalse(ApplicationStatus.SUBMITTED.canTransitionTo(ApplicationStatus.DRAFT));
        assertFalse(ApplicationStatus.SUBMITTED.canTransitionTo(ApplicationStatus.APPROVED));
    }

    @Test
    void testCanTransitionFromInReview() {
        assertTrue(ApplicationStatus.IN_REVIEW.canTransitionTo(ApplicationStatus.PENDING_SUPPLEMENT));
        assertTrue(ApplicationStatus.IN_REVIEW.canTransitionTo(ApplicationStatus.APPROVED));
        assertTrue(ApplicationStatus.IN_REVIEW.canTransitionTo(ApplicationStatus.REJECTED));
        assertFalse(ApplicationStatus.IN_REVIEW.canTransitionTo(ApplicationStatus.DRAFT));
        assertFalse(ApplicationStatus.IN_REVIEW.canTransitionTo(ApplicationStatus.SUBMITTED));
    }

    @Test
    void testCanTransitionFromPendingSupplement() {
        assertTrue(ApplicationStatus.PENDING_SUPPLEMENT.canTransitionTo(ApplicationStatus.SUBMITTED));
        assertTrue(ApplicationStatus.PENDING_SUPPLEMENT.canTransitionTo(ApplicationStatus.WITHDRAWN));
        assertFalse(ApplicationStatus.PENDING_SUPPLEMENT.canTransitionTo(ApplicationStatus.IN_REVIEW));
    }

    @Test
    void testTerminalStatuses() {
        assertTrue(ApplicationStatus.APPROVED.isTerminal());
        assertTrue(ApplicationStatus.REJECTED.isTerminal());
        assertTrue(ApplicationStatus.WITHDRAWN.isTerminal());
        assertFalse(ApplicationStatus.DRAFT.isTerminal());
        assertFalse(ApplicationStatus.SUBMITTED.isTerminal());
        assertFalse(ApplicationStatus.IN_REVIEW.isTerminal());
        assertFalse(ApplicationStatus.PENDING_SUPPLEMENT.isTerminal());
    }

    @Test
    void testTerminalStatusesHaveNoTransitions() {
        // Terminal statuses cannot transition to any other status
        assertFalse(ApplicationStatus.APPROVED.canTransitionTo(ApplicationStatus.DRAFT));
        assertFalse(ApplicationStatus.APPROVED.canTransitionTo(ApplicationStatus.SUBMITTED));
        assertFalse(ApplicationStatus.REJECTED.canTransitionTo(ApplicationStatus.DRAFT));
        assertFalse(ApplicationStatus.REJECTED.canTransitionTo(ApplicationStatus.SUBMITTED));
        assertFalse(ApplicationStatus.WITHDRAWN.canTransitionTo(ApplicationStatus.DRAFT));
        assertFalse(ApplicationStatus.WITHDRAWN.canTransitionTo(ApplicationStatus.SUBMITTED));
    }
}
