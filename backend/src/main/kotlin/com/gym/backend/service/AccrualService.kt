package com.gym.backend.service

import com.gym.backend.model.Accrual
import com.gym.backend.model.Booking
import com.gym.backend.model.Gym
import com.gym.backend.model.User
import com.gym.backend.repository.AccrualRepository
import com.gym.backend.repository.SurveyRepository
import com.gym.backend.repository.TrainerRateRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
class AccrualService(
    private val accrualRepository: AccrualRepository,
    private val trainerRateRepository: TrainerRateRepository,
    private val surveyRepository: SurveyRepository
) {

    fun calculateTrainerEarning(trainerId: Long, lessonType: String): Double {
        val customRate = trainerRateRepository.findByTrainerIdAndLessonType(trainerId, lessonType)
        if (customRate != null) {
            return customRate.amount
        }

        return when (lessonType) {
            "PT Bireysel" -> 250.0
            "PT Duo" -> 150.0
            "Reformer Pilates Bireysel" -> 200.0
            "Reformer Piletes 2'li Ders" -> 150.0
            "Reformer Piletes 3'lü Ders" -> 120.0
            "Reformer Piletes 4'lü Ders" -> 100.0
            "Reformer Seansı Kapat" -> 400.0
            else -> 0.0
        }
    }

    @Transactional
    fun saveAccrual(trainer: User, gym: Gym, booking: Booking, amount: Double) {
        val accrual = Accrual(
            trainer = trainer,
            gym = gym,
            booking = booking,
            amount = amount
        )
        accrualRepository.save(accrual)
    }

    @Transactional
    fun deleteAccrualByBooking(bookingId: Long) {
        val accrual = accrualRepository.findByBookingId(bookingId)
        if (accrual != null) {
            accrualRepository.delete(accrual)
        }
    }

    fun getUnpaidAmount(trainerId: Long): Double {
        return accrualRepository.sumUnpaidAmount(trainerId) ?: 0.0
    }

    fun getUnpaidDetails(trainerId: Long): List<Map<String, Any>> {
        val unpaidList = accrualRepository.findAllByTrainerIdAndIsPaidNotTrue(trainerId)
        return unpaidList.map { a ->
            val exerciseName = a.booking.performedExercises.firstOrNull()?.exerciseName ?: "PT Bireysel"
            mapOf(
                "id" to (a.id ?: 0L),
                "memberName" to a.booking.member.fullName,
                "date" to a.createdAt.toString(),
                "amount" to a.amount,
                "lessonType" to exerciseName
            )
        }
    }

    fun getTrainerStats(trainerId: Long): Map<String, Any> {
        val unpaidAmount = accrualRepository.sumUnpaidAmount(trainerId) ?: 0.0
        val totalLessons = accrualRepository.countByTrainerId(trainerId).toInt()
        val averageRating = surveyRepository.getAverageRatingForTrainer(trainerId) ?: 0.0
        val allAccruals = accrualRepository.findAllByTrainerIdOrderByCreatedAtDesc(trainerId)

        var ptCount = 0
        var reformerCount = 0
        var yogaCount = 0

        allAccruals.forEach { accrual ->
            val cat = accrual.booking.performedExercises.firstOrNull()?.exerciseName ?: "PT"
            if (cat.contains("Reformer", ignoreCase = true) || cat.contains("Pilates", ignoreCase = true)) {
                reformerCount++
            } else if (cat.contains("Yoga", ignoreCase = true)) {
                yogaCount++
            } else {
                ptCount++
            }
        }

        val recentLessons = allAccruals.take(10).map { accrual ->
            val lessonType = accrual.booking.performedExercises.firstOrNull()?.exerciseName ?: "Ders"
            mapOf(
                "id" to (accrual.id ?: 0L),
                "memberName" to accrual.booking.member.fullName,
                "lessonType" to lessonType,
                "date" to accrual.createdAt.toString(),
                "amount" to accrual.amount
            )
        }

        return mapOf(
            "unpaidAmount" to unpaidAmount,
            "totalLessons" to totalLessons,
            "averageRating" to averageRating,
            "ptCount" to ptCount,
            "reformerCount" to reformerCount,
            "yogaCount" to yogaCount,
            "recentLessons" to recentLessons
        )
    }

    @Transactional
    fun markAllAsPaid(trainerId: Long) {
        val unpaid = accrualRepository.findAllByTrainerIdAndIsPaidNotTrue(trainerId)
        unpaid.forEach { it.isPaid = true }
        accrualRepository.saveAll(unpaid)
    }
}
