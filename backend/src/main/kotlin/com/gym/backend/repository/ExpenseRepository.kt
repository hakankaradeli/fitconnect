package com.gym.backend.repository

import com.gym.backend.model.Expense
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository

@Repository
interface ExpenseRepository : JpaRepository<Expense, Long> {
    fun findAllByGymIdOrderByExpenseDateDesc(gymId: Long): List<Expense>

    @Query("SELECT SUM(e.amount) FROM Expense e WHERE e.gym.id = :gymId AND EXTRACT(MONTH FROM e.expenseDate) = :month")
    fun sumTotalExpensesByGymIdAndMonth(gymId: Long, month: Int): Double?
}
