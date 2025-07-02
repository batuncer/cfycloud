package com.cfy.employee.application.usecase;

import com.cfy.employee.application.metrics.EmployeeOperationMetrics;
import com.cfy.employee.domain.model.Employee;
import com.cfy.employee.domain.repository.EmployeeRepository;
import org.springframework.stereotype.Service;

@Service
public class UpdateEmployeeUseCase {

    private final EmployeeRepository employeeRepository;
    private final EmployeeOperationMetrics metrics;

    public UpdateEmployeeUseCase(EmployeeRepository employeeRepository, EmployeeOperationMetrics metrics) {
        this.employeeRepository = employeeRepository;
        this.metrics = metrics;
    }

    public Employee updateEmployee(Long id, Employee updatedEmployee) {
        Employee existingEmployee = employeeRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Employee not found"));

        // Update Employee
        existingEmployee.setFirstName(updatedEmployee.getFirstName());
        existingEmployee.setLastName(updatedEmployee.getLastName());
        existingEmployee.setEmail(updatedEmployee.getEmail());

        Employee saved = employeeRepository.save(existingEmployee);


        metrics.incrementUpdated();

        return saved;
    }
}
