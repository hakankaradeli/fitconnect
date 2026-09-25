package com.gym.backend.controller

import com.gym.backend.service.FinanceService
import org.springframework.http.ResponseEntity
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/finance")
class FinanceController(private val financeService: FinanceService) {

    // Üyenin kredi durumunu getir (Pozitif veya Negatif bakiye)
    @GetMapping("/balance/{memberId}")
    fun getBalance(@PathVariable memberId: Long): ResponseEntity<Any> {
        return try {
            val balance = financeService.getMemberBalance(memberId)
            ResponseEntity.ok(mapOf(
                "netBalance" to balance.netBalance,
                "totalPurchased" to balance.totalPurchased,
                "totalUsed" to balance.totalUsed
            ))
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to e.message))
        }
    }

    // Admin ödemeyi onaylar
    @PostMapping("/pay/{installmentId}")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'PERM_VIEW_REPORTS')")
    fun confirmPayment(@PathVariable installmentId: Long): ResponseEntity<Any> {
        return try {
            financeService.processPayment(installmentId)
            ResponseEntity.ok(mapOf("message" to "Ödeme başarıyla alındı, krediler yüklendi."))
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to e.message))
        }
    }

    // Admin manuel kredi tanımlar
    @PostMapping("/add-credit/{memberId}")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'PERM_MANAGE_USERS')")
    fun addManualCredit(
        @PathVariable memberId: Long,
        @RequestParam amount: Int,
        @RequestParam paymentAmount: Double,
        @RequestParam isPaid: Boolean,
        @RequestParam(required = false) @org.springframework.format.annotation.DateTimeFormat(iso = org.springframework.format.annotation.DateTimeFormat.ISO.DATE) dueDate: java.time.LocalDate?
    ): ResponseEntity<Any> {
        return try {
            financeService.addManualCredit(memberId, amount, paymentAmount, isPaid, dueDate)
            ResponseEntity.ok(mapOf("message" to "Kredi ve ödeme planı başarıyla kaydedildi."))
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to e.message))
        }
    }

    // Tüm ödemeleri getir
    @GetMapping("/installments/{gymId}")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'PERM_VIEW_REPORTS')")
    fun getInstallments(@PathVariable gymId: Long): ResponseEntity<Any> {
        return ResponseEntity.ok(financeService.getAllInstallmentsByGym(gymId))
    }
}
