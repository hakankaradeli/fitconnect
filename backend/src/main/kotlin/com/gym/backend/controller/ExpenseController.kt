package com.gym.backend.controller

import com.gym.backend.config.GlobalExceptionHandler
import com.gym.backend.dto.ExpenseCreateRequest
import com.gym.backend.service.ExpenseService
import org.springframework.http.ResponseEntity
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/expenses")
@PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'PERM_VIEW_REPORTS')")
class ExpenseController(private val expenseService: ExpenseService) {

    @PostMapping("/create")
    fun createExpense(@RequestBody request: ExpenseCreateRequest): ResponseEntity<Any> {
        return try {
            val expense = expenseService.createExpense(request)
            ResponseEntity.ok(expense)
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    @GetMapping("/gym/{gymId}")
    fun getExpenses(@PathVariable gymId: Long): ResponseEntity<Any> {
        return ResponseEntity.ok(expenseService.getExpensesByGym(gymId))
    }

    @DeleteMapping("/{expenseId}")
    fun deleteExpense(@PathVariable expenseId: Long): ResponseEntity<Any> {
        return try {
            expenseService.deleteExpense(expenseId)
            ResponseEntity.ok(mapOf("message" to "Gider kaydı silindi"))
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }
}
