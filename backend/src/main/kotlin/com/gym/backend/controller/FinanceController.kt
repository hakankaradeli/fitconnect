package com.gym.backend.controller

import com.gym.backend.config.GlobalExceptionHandler
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
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
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
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    // Admin manuel veya kısmi kredi tanımlar
    @PostMapping("/add-credit/{memberId}")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'PERM_MANAGE_USERS')")
    fun addManualCredit(
        @PathVariable memberId: Long,
        @RequestParam amount: Int,
        @RequestParam paymentAmount: Double,
        @RequestParam(required = false, defaultValue = "0.0") upfrontAmount: Double,
        @RequestParam(required = false, defaultValue = "true") isPaid: Boolean,
        @RequestParam(required = false) @org.springframework.format.annotation.DateTimeFormat(iso = org.springframework.format.annotation.DateTimeFormat.ISO.DATE) dueDate: java.time.LocalDate?
    ): ResponseEntity<Any> {
        return try {
            val actualUpfront = if (isPaid && upfrontAmount == 0.0) paymentAmount else upfrontAmount
            financeService.addPartialCredit(memberId, amount, paymentAmount, actualUpfront, dueDate)
            ResponseEntity.ok(mapOf("message" to "Kredi ve kısmi ödeme planı başarıyla kaydedildi."))
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    // Tüm ödemeleri getir
    @GetMapping("/installments/{gymId}")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'PERM_VIEW_REPORTS')")
    fun getInstallments(@PathVariable gymId: Long): ResponseEntity<Any> {
        return ResponseEntity.ok(financeService.getAllInstallmentsByGym(gymId))
    }

    // Admin kullanıcının kredisini düzenler
    @PutMapping("/credit/{memberId}")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'PERM_MANAGE_USERS', 'ROLE_SUPER_ADMIN')")
    fun updateCredit(
        @PathVariable memberId: Long,
        @RequestBody request: Map<String, Int>
    ): ResponseEntity<Any> {
        return try {
            val totalPurchased = request["totalPurchased"] ?: throw Exception("Toplam kredi zorunlu")
            val totalUsed = request["totalUsed"] ?: throw Exception("Kullanılan kredi zorunlu")
            val credit = financeService.updateMemberCredit(memberId, totalPurchased, totalUsed)
            ResponseEntity.ok(mapOf(
                "message" to "Kredi başarıyla güncellendi.",
                "netBalance" to credit.netBalance,
                "totalPurchased" to credit.totalPurchased,
                "totalUsed" to credit.totalUsed
            ))
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }
}
