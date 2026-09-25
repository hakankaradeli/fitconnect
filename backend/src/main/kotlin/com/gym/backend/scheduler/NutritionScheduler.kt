package com.gym.backend.scheduler

import com.gym.backend.model.Notification
import com.gym.backend.model.UserRole
import com.gym.backend.repository.NutritionRepository
import com.gym.backend.repository.NotificationRepository
import com.gym.backend.repository.UserRepository
import org.springframework.scheduling.annotation.Scheduled
import org.springframework.stereotype.Component
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime

@Component
class NutritionScheduler(
    private val nutritionRepository: NutritionRepository,
    private val notificationRepository: NotificationRepository,
    private val userRepository: UserRepository
) {

    // Her sabah saat 09:00'da çalışır (T-3 Gün İkazı & Gecikme Raporu)
    @Scheduled(cron = "0 0 9 * * *")
    @Transactional
    fun checkExpiringPlans() {
        val now = LocalDateTime.now()
        val targetDate = now.plusDays(3)

        // 1. T-3 Gün Kala İkazı: Süresi dolmasına 3 gün kalan planlar
        val expiringSoonPlans = nutritionRepository.findAll()
            .filter { it.expiryDate.isAfter(now) && it.expiryDate.isBefore(targetDate) }

        expiringSoonPlans.forEach { plan ->
            val message = "${plan.member.fullName} üyenizin beslenme planını güncelleyin (2 aylık sürenin dolmasına 3 gün kaldı)."
            notificationRepository.save(Notification(user = plan.trainer, message = message))
        }

        // 2. Gecikme Raporu: 2 aylık süresi dolduğu halde henüz güncellenmeyen planlar
        val expiredPlans = nutritionRepository.findAll()
            .filter { it.expiryDate.isBefore(now) }

        expiredPlans.forEach { plan ->
            val delayDays = java.time.Duration.between(plan.expiryDate, now).toDays()
            val adminWarning = "Beslenme Planı Gecikme Uyarısı: ${plan.trainer.fullName} eğitmeni, ${plan.member.fullName} üyesinin 2 aylık beslenme planını $delayDays gündür güncellememiştir."
            
            val admins = userRepository.findAllByGymIdAndRoleAndIsDeletedFalse(plan.member.gym.id!!, UserRole.ADMIN)
            admins.forEach { admin ->
                notificationRepository.save(Notification(user = admin, message = adminWarning))
            }
        }

        if (expiringSoonPlans.isNotEmpty() || expiredPlans.isNotEmpty()) {
            println("--- BESLENME SCHEDULER: ${expiringSoonPlans.size} eğitmene T-3 gün ikazı gönderildi, ${expiredPlans.size} gecikme yöneticiye raporlandı. ---")
        }
    }
}
