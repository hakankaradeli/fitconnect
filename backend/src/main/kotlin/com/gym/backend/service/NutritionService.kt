package com.gym.backend.service

import com.gym.backend.dto.NutritionPlanDto
import com.gym.backend.model.NutritionPlan
import com.gym.backend.model.Notification
import com.gym.backend.model.UserRole
import com.gym.backend.repository.NutritionRepository
import com.gym.backend.repository.UserRepository
import com.gym.backend.repository.NotificationRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime

@Service
class NutritionService(
    private val nutritionRepository: NutritionRepository,
    private val userRepository: UserRepository,
    private val notificationRepository: NotificationRepository
) {
    @Transactional
    fun savePlan(memberId: Long, trainerId: Long, dto: NutritionPlanDto): NutritionPlan {
        val member = userRepository.findById(memberId).orElseThrow { Exception("Üye bulunamadı") }
        val trainer = userRepository.findById(trainerId).orElseThrow { Exception("Eğitmen bulunamadı") }

        val plan = NutritionPlan(
            member = member,
            trainer = trainer,
            dailyCalories = dto.dailyCalories,
            protein = dto.protein,
            carbs = dto.carbs,
            fat = dto.fat,
            meals = dto.meals
        )
        val saved = nutritionRepository.save(plan)

        // 1. Üyeye bilgilendirme mesajı
        notificationRepository.save(Notification(
            user = member,
            message = "Eğitmeniniz ${trainer.fullName} yeni 2 aylık beslenme programınızı tanımladı."
        ))

        // 2. Yöneticiye raporlama (İçerik ve onay incelemesi için)
        val adminMsg = "Beslenme Planı Güncellendi: ${trainer.fullName} eğitmeni, ${member.fullName} üyesi için yeni plan oluşturdu (${dto.dailyCalories} kcal, ${dto.protein}g Protein, ${dto.carbs}g Karbonhidrat, ${dto.fat}g Yağ)."
        val admins = userRepository.findAllByGymIdAndRoleAndIsDeletedFalse(member.gym.id!!, UserRole.ADMIN)
        admins.forEach { admin ->
            notificationRepository.save(Notification(user = admin, message = adminMsg))
        }

        return saved
    }

    fun getActivePlan(memberId: Long): NutritionPlan? {
        return nutritionRepository.findFirstByMemberIdAndExpiryDateAfterOrderByCreatedAtDesc(
            memberId, 
            LocalDateTime.now()
        )
    }

    fun getMemberLatestPlan(memberId: Long): NutritionPlan? {
        return nutritionRepository.findFirstByMemberIdAndExpiryDateAfterOrderByCreatedAtDesc(
            memberId, 
            LocalDateTime.now().minusYears(10)
        )
    }

    fun getExpiredPlans(gymId: Long): List<Map<String, Any>> {
        val expired = nutritionRepository.findAllExpiredPlans(gymId, LocalDateTime.now())
        return expired.map { plan ->
            val delayDays = java.time.Duration.between(plan.expiryDate, LocalDateTime.now()).toDays()
            mapOf(
                "planId" to plan.id!!,
                "memberName" to plan.member.fullName,
                "memberId" to plan.member.id!!,
                "trainerName" to plan.trainer.fullName,
                "expiryDate" to plan.expiryDate.toString(),
                "delayDays" to delayDays
            )
        }
    }
}
