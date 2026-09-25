package com.gym.backend.service

import com.gym.backend.dto.*
import com.gym.backend.model.UserRole
import com.gym.backend.repository.ReportRepository
import com.gym.backend.repository.UserRepository
import com.gym.backend.repository.SurveyRepository
import com.gym.backend.repository.AccrualRepository
import com.gym.backend.repository.ExpenseRepository
import com.gym.backend.repository.BookingRepository
import org.springframework.stereotype.Service

@Service
class ReportService(
    private val reportRepository: ReportRepository,
    private val trainerRepository: UserRepository, // Eğitmenleri çekmek için
    private val surveyRepository: SurveyRepository,
    private val accrualRepository: AccrualRepository,
    private val expenseRepository: ExpenseRepository,
    private val bookingRepository: BookingRepository
) {
    fun generateMonthlyReport(gymId: Long, month: Int): AdminReportResponse {
        val revenue = reportRepository.getMonthlyRevenue(gymId, month) ?: 0.0
        val pending = reportRepository.getMonthlyPendingRevenue(gymId, month) ?: 0.0
        val trainerAccrualCosts = reportRepository.getMonthlyTrainerCosts(gymId, month) ?: 0.0
        val recordedExpenses = expenseRepository.sumTotalExpensesByGymIdAndMonth(gymId, month) ?: 0.0
        val totalCosts = trainerAccrualCosts + recordedExpenses
        
        // İstatistikleri çek
        val totalBookings = reportRepository.countBookingsByStatus(gymId, "PENDING", month) + 
                           reportRepository.countBookingsByStatus(gymId, "COMPLETED", month) +
                           reportRepository.countBookingsByStatus(gymId, "CANCELLED", month)
        
        val noShows = reportRepository.countBookingsByStatus(gymId, "NO_SHOW", month)
        val completed = reportRepository.countBookingsByStatus(gymId, "COMPLETED", month)

        // Eğitmen performanslarını hesapla
        val trainers = trainerRepository.findAllByGymIdAndRoleAndIsDeletedFalse(gymId, UserRole.TRAINER)
        val trainerPerformance = trainers.map { trainer ->
            TrainerReport(
                trainerName = trainer.fullName,
                lessonCount = accrualRepository.countByTrainerId(trainer.id!!).toInt(),
                totalEarning = accrualRepository.sumAmountByTrainerId(trainer.id) ?: 0.0,
                averageRating = surveyRepository.getAverageRatingForTrainer(trainer.id) ?: 0.0
            )
        }

        val bestTrainer = trainerPerformance.maxByOrNull { it.lessonCount * 10 + it.averageRating * 20 }

        return AdminReportResponse(
            month = "$month. Ay Raporu",
            financeSummary = FinanceSummary(
                totalRevenue = revenue,
                totalPending = pending,
                trainerCosts = totalCosts,
                netProfit = revenue - totalCosts
            ),
            trainerPerformance = trainerPerformance,
            attendanceStats = AttendanceStats(
                totalBookings = totalBookings,
                completedLessons = completed,
                noShowCount = noShows,
                cancellationRate = if (totalBookings > 0) (noShows.toDouble() / totalBookings) * 100 else 0.0
            ),
            trainerOfTheMonth = bestTrainer?.trainerName,
            trainerOfTheMonthScore = bestTrainer?.averageRating
        )
    }

    fun getTrainerOfTheMonth(gymId: Long): Map<String, Any?> {
        val currentMonth = java.time.LocalDate.now().monthValue
        val report = generateMonthlyReport(gymId, currentMonth)
        return mapOf(
            "trainerName" to report.trainerOfTheMonth,
            "rating" to report.trainerOfTheMonthScore
        )
    }

    fun getUnperformedReport(gymId: Long, start: java.time.LocalDateTime, end: java.time.LocalDateTime): List<Map<String, Any?>> {
        val unperformed = bookingRepository.findDailyUnperformedBookings(gymId, start, end)
        val formatter = java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")

        return unperformed.map { booking ->
            mapOf(
                "bookingId" to booking.id,
                "memberName" to booking.member.fullName,
                "trainerName" to booking.trainer.fullName,
                "time" to booking.startTime.format(formatter),
                "status" to booking.status,
                "reason" to (booking.cancellationReason ?: "Neden belirtilmedi")
            )
        }
    }

    fun getDailyUnperformedReport(gymId: Long, date: java.time.LocalDate): List<Map<String, Any?>> {
        val start = date.atStartOfDay()
        val end = date.atTime(23, 59, 59)
        return getUnperformedReport(gymId, start, end)
    }

    fun getTrainerComplaints(gymId: Long): List<Map<String, Any?>> {
        val complaints = surveyRepository.findAllComplaintsByGymId(gymId)
        return complaints.map { survey ->
            mapOf(
                "surveyId" to survey.id,
                "memberName" to survey.booking.member.fullName,
                "trainerName" to survey.booking.trainer.fullName,
                "rating" to survey.rating,
                "comment" to survey.comment,
                "lessonDate" to survey.booking.startTime.toString()
            )
        }
    }
}
