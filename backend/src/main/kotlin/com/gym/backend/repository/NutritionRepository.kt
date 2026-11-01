package com.gym.backend.repository

import com.gym.backend.model.NutritionPlan
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository
import java.time.LocalDateTime

@Repository
interface NutritionRepository : JpaRepository<NutritionPlan, Long> {
    // Üyenin en son oluşturulmuş ve süresi dolmamış planını getir
    fun findFirstByMemberIdAndExpiryDateAfterOrderByCreatedAtDesc(
        memberId: Long, 
        now: LocalDateTime
    ): NutritionPlan?

    fun findFirstByMemberIdOrderByCreatedAtDesc(memberId: Long): NutritionPlan?

    @org.springframework.data.jpa.repository.Query("SELECT n FROM NutritionPlan n WHERE n.member.gym.id = :gymId AND n.expiryDate < :now ORDER BY n.expiryDate ASC")
    fun findAllExpiredPlans(gymId: Long, now: LocalDateTime): List<NutritionPlan>
}
