package com.gym.backend.repository

import com.gym.backend.model.Installment
import com.gym.backend.model.PaymentStatus
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository
import java.time.LocalDate

@Repository
interface InstallmentRepository : JpaRepository<Installment, Long> {
    fun findAllByMemberId(memberId: Long): List<Installment>
    fun findAllByDueDateAndStatus(dueDate: LocalDate, status: PaymentStatus): List<Installment>

    @Query("SELECT SUM(i.amount) FROM Installment i WHERE i.gymId = :gymId AND i.status = :status")
    fun sumAmountByGymIdAndStatus(gymId: Long, status: PaymentStatus): Double?

    fun findAllByGymIdOrderByDueDateDesc(gymId: Long): List<Installment>
}
