package com.gym.backend.dto

import com.gym.backend.model.ExpenseCategory
import java.time.LocalDate

data class ExpenseCreateRequest(
    val gymId: Long,
    val category: ExpenseCategory,
    val title: String,
    val amount: Double,
    val expenseDate: LocalDate,
    val trainerId: Long? = null,
    val notes: String? = null
)
