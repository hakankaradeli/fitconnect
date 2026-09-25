package com.gym.backend.service

import com.gym.backend.model.Accrual
import com.gym.backend.model.Booking
import com.gym.backend.model.Gym
import com.gym.backend.model.User
import com.gym.backend.repository.AccrualRepository
import com.gym.backend.repository.TrainerRateRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
class AccrualService(
    private val accrualRepository: AccrualRepository,
    private val trainerRateRepository: TrainerRateRepository
) {

    // PRD Madde 6: Ders tipine göre hakediş tutarını belirle
    fun calculateTrainerEarning(trainerId: Long, lessonType: String): Double {
        // Önce eğitmene özel tanımlanmış bir ücret var mı diye bak
        val customRate = trainerRateRepository.findByTrainerIdAndLessonType(trainerId, lessonType)
        if (customRate != null) {
            return customRate.amount
        }

        // Yoksa varsayılan tarifeyi kullan
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

    fun getUnpaidAmount(trainerId: Long): Double {
        return accrualRepository.sumUnpaidAmount(trainerId) ?: 0.0
    }

    @Transactional
    fun markAllAsPaid(trainerId: Long) {
        val unpaid = accrualRepository.findAllByTrainerIdAndIsPaidNotTrue(trainerId)
        unpaid.forEach { it.isPaid = true }
        accrualRepository.saveAll(unpaid)
    }
}
