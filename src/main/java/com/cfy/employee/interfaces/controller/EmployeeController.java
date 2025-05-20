package com.cfy.employee.interfaces.controller;

import com.cfy.employee.application.usecase.AddEmployeeUseCase;
import com.cfy.employee.application.usecase.DeleteEmployeeUseCase;
import com.cfy.employee.application.usecase.GetAllEmployeesUseCase;
import com.cfy.employee.application.usecase.UpdateEmployeeUseCase;
import com.cfy.employee.domain.model.Employee;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/employees")
@CrossOrigin(origins = "http://cfycloud.s3-website-eu-west-1.amazonaws.com")
public class EmployeeController {
    private final AddEmployeeUseCase addEmployeeUseCase;
    private final UpdateEmployeeUseCase updateEmployeeUseCase;
    private final DeleteEmployeeUseCase deleteEmployeeUseCase;
    private final GetAllEmployeesUseCase getAllEmployeesUseCase;

    public EmployeeController(AddEmployeeUseCase addEmployeeUseCase,
                              UpdateEmployeeUseCase updateEmployeeUseCase,
                              DeleteEmployeeUseCase deleteEmployeeUseCase,
                              GetAllEmployeesUseCase getAllEmployeesUseCase) {
        this.addEmployeeUseCase = addEmployeeUseCase;
        this.updateEmployeeUseCase = updateEmployeeUseCase;
        this.deleteEmployeeUseCase = deleteEmployeeUseCase;
        this.getAllEmployeesUseCase = getAllEmployeesUseCase;
    }

    // Add Employee
    @PostMapping
    public ResponseEntity<Employee> addEmployee(@RequestBody Employee employee) {
        Employee savedEmployee = addEmployeeUseCase.addEmployee(employee);
        return ResponseEntity.ok(savedEmployee);
    }

    // Update Employee
    @PutMapping("/{id}")
    public ResponseEntity<Employee> updateEmployee(@PathVariable Long id, @RequestBody Employee employee) {
        employee.setId(id); // id'yi DTO'ya ekliyoruz
        Employee updatedEmployee = updateEmployeeUseCase.updateEmployee(id,employee);
        return ResponseEntity.ok(updatedEmployee);
    }

    // Get All Employees
    @GetMapping
    public ResponseEntity<List<Employee>> getAllEmployees() {
        List<Employee> employees = getAllEmployeesUseCase.getAllEmployees();
        return ResponseEntity.ok(employees);
    }

    // Delete Employee
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteEmployee(@PathVariable Long id) {
        deleteEmployeeUseCase.deleteEmployee(id);
        return ResponseEntity.noContent().build();
    }
}