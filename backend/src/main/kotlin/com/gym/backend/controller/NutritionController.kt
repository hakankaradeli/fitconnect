package com.gym.backend.controller

import com.gym.backend.config.GlobalExceptionHandler
import com.gym.backend.dto.NutritionPlanDto
import com.gym.backend.model.NutritionPlan
import com.gym.backend.service.NutritionService
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/nutrition")
class NutritionController(private val nutritionService: NutritionService) {

    // Eğitmen yeni plan girer
    @PostMapping("/assign")
    fun assignPlan(@RequestParam memberId: Long, @RequestParam trainerId: Long, @RequestBody dto: NutritionPlanDto): ResponseEntity<Any> {
        return try {
            val savedPlan = nutritionService.savePlan(memberId, trainerId, dto)
            ResponseEntity.ok(savedPlan)
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    // Üye kendi aktif planını çeker
    @GetMapping("/my-plan/{memberId}")
    fun getMyPlan(@PathVariable memberId: Long): ResponseEntity<Any> {
        val plan = nutritionService.getActivePlan(memberId)
            ?: return ResponseEntity.status(404).body(mapOf("message" to "Aktif beslenme planınız bulunmamaktadır."))
        
        return ResponseEntity.ok(plan)
    }

    // Yönetici veya Eğitmen üyenin en son planını çeker
    @GetMapping("/member-plan/{memberId}")
    @org.springframework.security.access.prepost.PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'ROLE_TRAINER', 'ROLE_MEMBER')")
    fun getMemberPlan(@PathVariable memberId: Long): ResponseEntity<Any> {
        val plan = nutritionService.getMemberLatestPlan(memberId)
            ?: return ResponseEntity.status(404).body(mapOf("message" to "Üyeye ait kaydedilmiş beslenme planı bulunamadı."))
        
        return ResponseEntity.ok(plan)
    }

    // Yönetici için 60 günü geçmiş/gecikmiş plan raporları
    @GetMapping("/expired-reports/{gymId}")
    @org.springframework.security.access.prepost.PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'PERM_VIEW_REPORTS')")
    fun getExpiredReports(@PathVariable gymId: Long): ResponseEntity<Any> {
        return ResponseEntity.ok(nutritionService.getExpiredPlans(gymId))
    }

    // Yönetici veya eğitmen için beslenme planı olmayan üyeler
    @GetMapping("/without-plan/{gymId}")
    @org.springframework.security.access.prepost.PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'PERM_VIEW_REPORTS', 'ROLE_TRAINER')")
    fun getMembersWithoutPlan(@PathVariable gymId: Long): ResponseEntity<Any> {
        return ResponseEntity.ok(nutritionService.getMembersWithoutNutritionPlan(gymId))
    }
}
