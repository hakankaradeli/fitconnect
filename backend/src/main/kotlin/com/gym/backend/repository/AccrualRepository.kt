package com.gym.backend.repository

import com.gym.backend.model.Accrual
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository

@Repository
interface AccrualRepository : JpaRepository<Accrual, Long> {
    fun findAllByTrainerId(trainerId: Long): List<Accrual>

    @Query("SELECT a FROM Accrual a WHERE a.trainer.id = :trainerId AND (a.isPaid IS NULL OR a.isPaid = false)")
    fun findAllByTrainerIdAndIsPaidNotTrue(trainerId: Long): List<Accrual>
    
    @Query("SELECT SUM(a.amount) FROM Accrual a WHERE a.trainer.id = :trainerId AND (a.isPaid IS NULL OR a.isPaid = false)")
    fun sumUnpaidAmount(trainerId: Long): Double?

    fun countByTrainerId(trainerId: Long): Long

    @Query("SELECT SUM(a.amount) FROM Accrual a WHERE a.trainer.id = :trainerId")
    fun sumAmountByTrainerId(trainerId: Long): Double?
}
