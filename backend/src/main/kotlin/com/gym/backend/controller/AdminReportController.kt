package com.gym.backend.controller

import com.gym.backend.dto.AdminReportResponse
import com.gym.backend.service.ReportService
import org.springframework.http.ResponseEntity
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/admin/reports")
class AdminReportController(private val reportService: ReportService) {

    @GetMapping("/monthly")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'PERM_VIEW_REPORTS')") // Admin veya Yetkili Eğitmen
    fun getMonthlyReport(
        @RequestParam gymId: Long,
        @RequestParam month: Int
  ): ResponseEntity<AdminReportResponse> {
        val report = reportService.generateMonthlyReport(gymId, month)
        return ResponseEntity.ok(report)
    }

    @GetMapping("/trainer-of-the-month")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'ROLE_TRAINER', 'ROLE_MEMBER', 'PERM_VIEW_REPORTS')")
    fun getTrainerOfTheMonth(@RequestParam gymId: Long): ResponseEntity<Any> {
        val result = reportService.getTrainerOfTheMonth(gymId)
        return ResponseEntity.ok(result)
    }

    @GetMapping("/daily-unperformed")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'PERM_VIEW_REPORTS')")
    fun getDailyUnperformed(
        @RequestParam gymId: Long,
        @RequestParam @org.springframework.format.annotation.DateTimeFormat(iso = org.springframework.format.annotation.DateTimeFormat.ISO.DATE) date: java.time.LocalDate
    ): ResponseEntity<Any> {
        return ResponseEntity.ok(reportService.getDailyUnperformedReport(gymId, date))
    }

    @GetMapping("/unperformed-range")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'PERM_VIEW_REPORTS')")
    fun getUnperformedRange(
        @RequestParam gymId: Long,
        @RequestParam @org.springframework.format.annotation.DateTimeFormat(iso = org.springframework.format.annotation.DateTimeFormat.ISO.DATE_TIME) start: java.time.LocalDateTime,
        @RequestParam @org.springframework.format.annotation.DateTimeFormat(iso = org.springframework.format.annotation.DateTimeFormat.ISO.DATE_TIME) end: java.time.LocalDateTime
    ): ResponseEntity<Any> {
        return ResponseEntity.ok(reportService.getUnperformedReport(gymId, start, end))
    }

    @GetMapping("/trainer-complaints")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'PERM_VIEW_REPORTS')")
    fun getTrainerComplaints(@RequestParam gymId: Long): ResponseEntity<Any> {
        return ResponseEntity.ok(reportService.getTrainerComplaints(gymId))
    }
}
