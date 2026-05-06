package vn.dcid.service;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import vn.dcid.domain.entity.Appointment;
import vn.dcid.dto.request.BookAppointmentRequest;
import vn.dcid.dto.response.AppointmentDTO;
import vn.dcid.repository.AppointmentRepository;

import java.util.UUID;

@Service
public class AppointmentService {

    private final AppointmentRepository appointmentRepository;

    public AppointmentService(AppointmentRepository appointmentRepository) {
        this.appointmentRepository = appointmentRepository;
    }

    public AppointmentDTO bookAppointment(UUID applicationId, BookAppointmentRequest request) {
        throw new UnsupportedOperationException("TODO: Implement appointment booking");
    }

    public AppointmentDTO getAppointment(UUID id) {
        throw new UnsupportedOperationException("TODO: Implement get appointment");
    }

    public Page<AppointmentDTO> getAppointmentsForCitizen(UUID citizenId, Pageable pageable) {
        throw new UnsupportedOperationException("TODO: Implement get appointments for citizen");
    }

    public Page<AppointmentDTO> getAppointmentsForOfficer(UUID officerId, Pageable pageable) {
        throw new UnsupportedOperationException("TODO: Implement get appointments for officer");
    }

    public AppointmentDTO updateAppointment(UUID id, BookAppointmentRequest request) {
        throw new UnsupportedOperationException("TODO: Implement update appointment");
    }

    public void cancelAppointment(UUID id) {
        throw new UnsupportedOperationException("TODO: Implement cancel appointment");
    }
}
