package com.gym.backend.repository

import com.gym.backend.model.Booking
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository

@Repository
interface ReportRepository : JpaRepository<Booking, Long> {

    // Belirli bir aydaki toplam tahsilatı getir
    @Query("SELECT SUM(i.amount) FROM Installment i WHERE i.gymId = :gymId AND i.status = com.gym.backend.model.PaymentStatus.PAID AND EXTRACT(MONTH FROM i.dueDate) = :month")
    fun getMonthlyRevenue(gymId: Long, month: Int): Double?

    // Belirli bir aydaki bekleyen alacakları getir
    @Query("SELECT SUM(i.amount) FROM Installment i WHERE i.gymId = :gymId AND i.status = com.gym.backend.model.PaymentStatus.PENDING AND EXTRACT(MONTH FROM i.dueDate) = :month")
    fun getMonthlyPendingRevenue(gymId: Long, month: Int): Double?

    // Belirli bir aydaki toplam eğitmen hakediş yükünü getir
    @Query("SELECT SUM(a.amount) FROM Accrual a WHERE a.gym.id = :gymId AND EXTRACT(MONTH FROM a.createdAt) = :month")
    fun getMonthlyTrainerCosts(gymId: Long, month: Int): Double?

    // No-Show veya tamamlanan ders istatistiklerini getir
    @Query("SELECT COUNT(b) FROM Booking b WHERE b.gym.id = :gymId AND b.status = :status AND EXTRACT(MONTH FROM b.startTime) = :month")
    fun countBookingsByStatus(gymId: Long, status: String, month: Int): Int
}
