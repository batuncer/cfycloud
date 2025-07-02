package com.cfy.employee.application.metrics;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.stereotype.Component;

@Component
public class EmployeeOperationMetrics {

    private final Counter newEmployeeCounter;
    private final Counter removedEmployeeCounter;
    private final Counter updatedEmployeeCounter;

    public EmployeeOperationMetrics(MeterRegistry meterRegistry) {
        this.newEmployeeCounter = Counter.builder("employee_operations_total")
                .tag("operation", "new")
                .description("Total new employees added")
                .register(meterRegistry);

        this.removedEmployeeCounter = Counter.builder("employee_operations_total")
                .tag("operation", "removed")
                .description("Total employees removed")
                .register(meterRegistry);

        this.updatedEmployeeCounter = Counter.builder("employee_operations_total")
                .tag("operation", "updated")
                .description("Total employees updated")
                .register(meterRegistry);
    }

    public void incrementNew() {
        newEmployeeCounter.increment();
    }

    public void incrementRemoved() {
        removedEmployeeCounter.increment();
    }

    public void incrementUpdated() {
        updatedEmployeeCounter.increment();
    }
}