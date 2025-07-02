package com.cfy.employee.application.usecase;

import com.cfy.employee.application.metrics.EmployeeOperationMetrics;
import com.cfy.employee.domain.repository.EmployeeRepository;
import org.springframework.stereotype.Service;

@Service
public class DeleteEmployeeUseCase {

    private final EmployeeRepository employeeRepository;
    private final EmployeeOperationMetrics metrics;

    public DeleteEmployeeUseCase(EmployeeRepository employeeRepository, EmployeeOperationMetrics metrics) {
        this.employeeRepository = employeeRepository;
        this.metrics = metrics;
    }

    public void deleteEmployee(Long employeeId) {

        employeeRepository.findById(employeeId)
                .orElseThrow(() -> new IllegalArgumentException("Employee not found"));


        employeeRepository.deleteById(employeeId);

        metrics.incrementRemoved();
    }
}