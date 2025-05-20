package com.cfy.employee.application.usecase;

import com.cfy.employee.domain.model.Employee;
import com.cfy.employee.domain.repository.EmployeeRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class GetAllEmployeesUseCase {

    private final EmployeeRepository employeeRepository;

    public GetAllEmployeesUseCase(EmployeeRepository employeeRepository) {
        this.employeeRepository = employeeRepository;
    }

    public List<Employee> getAllEmployees() {
        return employeeRepository.findAll();
    }
}
