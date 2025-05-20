package com.cfy.employee.application.usecase;

import com.cfy.employee.domain.repository.EmployeeRepository;
import org.springframework.stereotype.Service;

@Service
public class DeleteEmployeeUseCase {

    private final EmployeeRepository employeeRepository;

    public DeleteEmployeeUseCase(EmployeeRepository employeeRepository) {
        this.employeeRepository = employeeRepository;
    }

    public void deleteEmployee(Long employeeId) {
        employeeRepository.findById(employeeId).orElseThrow(() -> new IllegalArgumentException("Employee not found"));
        employeeRepository.deleteById(employeeId);
    }
}
