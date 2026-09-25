package com.gym.backend.controller

import com.gym.backend.service.AccrualService
import org.springframework.http.ResponseEntity
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/accruals")
class AccrualController(private val accrualService: AccrualService) {

    @GetMapping("/unpaid/{trainerId}")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'PERM_VIEW_REPORTS')")
    fun getUnpaidAmount(@PathVariable trainerId: Long): ResponseEntity<Any> {
        return ResponseEntity.ok(mapOf("amount" to accrualService.getUnpaidAmount(trainerId)))
    }

    @PostMapping("/pay-all/{trainerId}")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'PERM_VIEW_REPORTS')")
    fun payAll(@PathVariable trainerId: Long): ResponseEntity<Any> {
        accrualService.markAllAsPaid(trainerId)
        return ResponseEntity.ok(mapOf("message" to "Tüm hakedişler ödendi olarak işaretlendi"))
    }
}
