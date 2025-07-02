package com.cfy.employee.application.scheduler;


import com.cfy.employee.application.metrics.EmployeeMetrics;
import com.cfy.employee.domain.repository.EmployeeRepository;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public class EmployeeCountScheduler {

    private final EmployeeRepository employeeRepository;
    private final EmployeeMetrics employeeMetrics;

    public EmployeeCountScheduler(EmployeeRepository employeeRepository, EmployeeMetrics employeeMetrics) {
        this.employeeRepository = employeeRepository;
        this.employeeMetrics = employeeMetrics;
    }

    @Scheduled(fixedRate = 30000)
    public void updateEmployeeCountMetric() {
        long count = employeeRepository.count();
        employeeMetrics.setEmployeeCount((int) count);
    }
}