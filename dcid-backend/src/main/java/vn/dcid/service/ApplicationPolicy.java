package vn.dcid.service;

import org.springframework.stereotype.Component;
import vn.dcid.domain.entity.Application;
import vn.dcid.domain.enums.ApplicationStatus;
import vn.dcid.domain.enums.UserRole;
import vn.dcid.exception.ForbiddenException;
import vn.dcid.exception.PolicyViolationException;

import java.util.UUID;

@Component
public class ApplicationPolicy {

    public void assertCanSubmit(Application application, UUID userId) {
        // TODO: Implement submit policy check
        if (!application.getApplicantId().equals(userId)) {
            throw new ForbiddenException("Only the applicant can submit this application");
        }
        if (!application.getStatus().canTransitionTo(ApplicationStatus.SUBMITTED)) {
            throw new PolicyViolationException(
                    "Cannot submit application in status: " + application.getStatus());
        }
    }

    public void assertCanApprove(Application application, UUID officerId) {
        // TODO: Implement approval policy check
        if (application.getAssignedOfficerId() == null ||
                !application.getAssignedOfficerId().equals(officerId)) {
            throw new ForbiddenException("Only the assigned officer can approve this application");
        }
        if (!application.getStatus().canTransitionTo(ApplicationStatus.APPROVED)) {
            throw new PolicyViolationException(
                    "Cannot approve application in status: " + application.getStatus());
        }
    }

    public void assertCanReject(Application application, UUID officerId) {
        // TODO: Implement rejection policy check
        if (application.getAssignedOfficerId() == null ||
                !application.getAssignedOfficerId().equals(officerId)) {
            throw new ForbiddenException("Only the assigned officer can reject this application");
        }
        if (!application.getStatus().canTransitionTo(ApplicationStatus.REJECTED)) {
            throw new PolicyViolationException(
                    "Cannot reject application in status: " + application.getStatus());
        }
    }

    public void assertCanWithdraw(Application application, UUID userId) {
        // TODO: Implement withdrawal policy check
        if (!application.getApplicantId().equals(userId)) {
            throw new ForbiddenException("Only the applicant can withdraw this application");
        }
        if (!application.getStatus().canTransitionTo(ApplicationStatus.WITHDRAWN)) {
            throw new PolicyViolationException(
                    "Cannot withdraw application in status: " + application.getStatus());
        }
    }

    public void assertCanReview(Application application, UUID officerId) {
        // TODO: Implement review policy check
        if (application.getAssignedOfficerId() == null ||
                !application.getAssignedOfficerId().equals(officerId)) {
            throw new ForbiddenException("Only the assigned officer can review this application");
        }
        if (application.getStatus() != ApplicationStatus.IN_REVIEW) {
            throw new PolicyViolationException(
                    "Application must be in IN_REVIEW status to be reviewed");
        }
    }
}
