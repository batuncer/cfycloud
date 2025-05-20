package com.cfy.employee.application.usecase;

import com.cfy.employee.domain.model.Employee;
import com.cfy.employee.domain.repository.EmployeeRepository;
import org.springframework.stereotype.Service;

@Service
public class AddEmployeeUseCase {

    private final EmployeeRepository employeeRepository;

    public AddEmployeeUseCase(EmployeeRepository employeeRepository) {
        this.employeeRepository = employeeRepository;
    }

    public Employee addEmployee(Employee employee) {
        return employeeRepository.save(employee);
    }
}
