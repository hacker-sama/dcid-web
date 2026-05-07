package vn.dcid.service;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.dcid.domain.entity.Application;
import vn.dcid.domain.entity.ApplicationStatusHistory;
import vn.dcid.domain.enums.ApplicationStatus;
import vn.dcid.dto.request.ReviewApplicationRequest;
import vn.dcid.dto.request.SubmitApplicationRequest;
import vn.dcid.dto.request.UpdateApplicationRequest;
import vn.dcid.dto.response.ApplicationDTO;
import vn.dcid.dto.response.ApplicationDetailDTO;
import vn.dcid.repository.ApplicationRepository;
import vn.dcid.repository.ApplicationStatusHistoryRepository;
import vn.dcid.security.SecurityContextHelper;

import java.util.List;
import java.util.UUID;

@Service
@Transactional
public class ApplicationService {

    private final ApplicationRepository applicationRepository;
    private final ApplicationStatusHistoryRepository statusHistoryRepository;

    public ApplicationService(
            ApplicationRepository applicationRepository,
            ApplicationStatusHistoryRepository statusHistoryRepository) {
        this.applicationRepository = applicationRepository;
        this.statusHistoryRepository = statusHistoryRepository;
    }

    public ApplicationDTO createDraft(SubmitApplicationRequest request) {
        throw new UnsupportedOperationException("TODO: Implement create draft application");
    }

    public ApplicationDTO submitApplication(UUID id) {
        throw new UnsupportedOperationException("TODO: Implement submit application");
    }

    public ApplicationDTO updateApplication(UUID id, UpdateApplicationRequest request) {
        throw new UnsupportedOperationException("TODO: Implement update application");
    }

    public ApplicationDetailDTO getApplication(UUID id) {
        throw new UnsupportedOperationException("TODO: Implement get application");
    }

    public Page<ApplicationDTO> getMyApplications(Pageable pageable) {
        throw new UnsupportedOperationException("TODO: Implement get my applications");
    }

    public Page<ApplicationDTO> getAssignedApplications(ApplicationStatus status, Pageable pageable) {
        throw new UnsupportedOperationException("TODO: Implement get assigned applications");
    }

    public ApplicationDTO reviewApplication(UUID id, ReviewApplicationRequest request) {
        throw new UnsupportedOperationException("TODO: Implement review application");
    }

    public ApplicationDTO assignOfficer(UUID id, UUID officerId) {
        throw new UnsupportedOperationException("TODO: Implement assign officer");
    }

    public ApplicationDTO withdrawApplication(UUID id) {
        throw new UnsupportedOperationException("TODO: Implement withdraw application");
    }

    public void deleteApplication(UUID id) {
        throw new UnsupportedOperationException("TODO: Implement delete application");
    }

    public List<ApplicationDTO> getOverdueApplications() {
        throw new UnsupportedOperationException("TODO: Implement get overdue applications");
    }

    private void recordStatusChange(UUID applicationId, ApplicationStatus from, ApplicationStatus to, String note) {
        throw new UnsupportedOperationException("TODO: Implement record status change");
    }
}
