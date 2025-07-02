package com.cfy.employee.application.usecase;

import com.cfy.employee.application.metrics.EmployeeOperationMetrics;
import com.cfy.employee.domain.model.Employee;
import com.cfy.employee.domain.repository.EmployeeRepository;
import org.springframework.stereotype.Service;

@Service
public class AddEmployeeUseCase {

    private final EmployeeRepository employeeRepository;
    private final EmployeeOperationMetrics metrics;


    public AddEmployeeUseCase(EmployeeRepository employeeRepository, EmployeeOperationMetrics metrics) {
        this.employeeRepository = employeeRepository;
        this.metrics = metrics;
    }

    public Employee addEmployee(Employee employee) {
        Employee savedEmployee = employeeRepository.save(employee);
        metrics.incrementNew();
        return savedEmployee;

    }
}
