package com.gym.backend.dto

data class AdminReportResponse(
    val month: String,
    val financeSummary: FinanceSummary,
    val trainerPerformance: List<TrainerReport>,
    val attendanceStats: AttendanceStats,
    val trainerOfTheMonth: String? = null,
    val trainerOfTheMonthScore: Double? = null
)

data class FinanceSummary(
    val totalRevenue: Double,    // Toplam Tahsil Edilen (Paid Installments)
    val totalPending: Double,    // Bekleyen Alacaklar (Pending Installments)
    val trainerCosts: Double,    // Eğitmen Hakediş Giderleri
    val netProfit: Double        // Net Kar/Zarar (Revenue - TrainerCosts)
)

data class TrainerReport(
    val trainerName: String,
    val lessonCount: Int,
    val totalEarning: Double,
    val averageRating: Double   // PRD Madde 5: 1-5 yıldız anket ortalaması
)

data class AttendanceStats(
    val totalBookings: Int,
    val completedLessons: Int,
    val todayLessons: Int = 0,
    val todayCompletedLessons: Int = 0,
    val totalCompletedAllTime: Int = 0,
    val noShowCount: Int,       // PRD Madde 4: Derse gelmeyenler
    val cancellationRate: Double
)
