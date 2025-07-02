package com.cfy.employee.application.metrics;

import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Gauge;
import org.springframework.stereotype.Component;

import java.util.concurrent.atomic.AtomicInteger;

@Component
public class EmployeeMetrics {

    private final AtomicInteger employeeCount = new AtomicInteger(0);

    public EmployeeMetrics(MeterRegistry meterRegistry) {
        Gauge.builder("employee_count", employeeCount, AtomicInteger::get)
                .description("Number of employees in the system")
                .register(meterRegistry);
    }

    public void setEmployeeCount(int count) {
        this.employeeCount.set(count);
    }

    public int getEmployeeCount() {
        return this.employeeCount.get();
    }
}
