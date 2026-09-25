package com.gym.backend.service

import com.gym.backend.dto.ExpenseCreateRequest
import com.gym.backend.model.Expense
import com.gym.backend.repository.ExpenseRepository
import com.gym.backend.repository.GymRepository
import com.gym.backend.repository.UserRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
class ExpenseService(
    private val expenseRepository: ExpenseRepository,
    private val gymRepository: GymRepository,
    private val userRepository: UserRepository
) {
    @Transactional
    fun createExpense(request: ExpenseCreateRequest): Expense {
        val gym = gymRepository.findById(request.gymId).orElseThrow { Exception("Salon bulunamadı!") }
        val trainer = request.trainerId?.let { 
            userRepository.findById(it).orElse(null) 
        }

        val expense = Expense(
            gym = gym,
            category = request.category,
            title = request.title,
            amount = request.amount,
            expenseDate = request.expenseDate,
            trainer = trainer,
            notes = request.notes
        )

        return expenseRepository.save(expense)
    }

    fun getExpensesByGym(gymId: Long): List<Expense> {
        return expenseRepository.findAllByGymIdOrderByExpenseDateDesc(gymId)
    }

    @Transactional
    fun deleteExpense(expenseId: Long) {
        expenseRepository.deleteById(expenseId)
    }

    fun getMonthlyExpenses(gymId: Long, month: Int): Double {
        return expenseRepository.sumTotalExpensesByGymIdAndMonth(gymId, month) ?: 0.0
    }
}
