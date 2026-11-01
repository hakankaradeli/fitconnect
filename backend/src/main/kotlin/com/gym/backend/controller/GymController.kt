package com.gym.backend.controller

import com.gym.backend.config.GlobalExceptionHandler
import com.gym.backend.service.GymService
import org.springframework.http.ResponseEntity
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.web.bind.annotation.*

data class GymBrandingUpdateRequest(
    val gymName: String? = null,
    val primaryColor: String? = null,
    val secondaryColor: String? = null,
    val isGradient: Boolean? = null,
    val logoUrl: String? = null,
    val address: String? = null,
    val phone: String? = null,
    val email: String? = null,
    val instagram: String? = null,
    val website: String? = null,
    val offeredLessonGroups: String? = null
)

data class GymWorkingHoursRequest(
    val workingDays: String,
    val openTime: String,
    val closeTime: String,
    val maxCancellationsAllowed: Int? = 4
)

@RestController
@RequestMapping("/api/gyms")
class GymController(private val gymService: GymService) {

    @GetMapping("/branding/{gymId}")
    @PreAuthorize("permitAll()")
    fun getBranding(@PathVariable gymId: Long): ResponseEntity<Any> {
        return try {
            val gym = gymService.getGymBranding(gymId)
            ResponseEntity.ok(mapOf(
                "gymId" to gym.id,
                "gymName" to gym.name,
                "primaryColor" to (gym.primaryColor ?: "#3F51B5"),
                "secondaryColor" to (gym.secondaryColor ?: "#00BFA5"),
                "isGradient" to (gym.isGradient ?: false),
                "logoUrl" to gym.logoUrl,
                "address" to gym.address,
                "phone" to gym.phone,
                "email" to gym.email,
                "instagram" to gym.instagram,
                "website" to gym.website,
                "offeredLessonGroups" to (gym.offeredLessonGroups ?: "PT,Pilates,Kickboks,Yoga"),
                "workingDays" to (gym.workingDays ?: "1,2,3,4,5,6"),
                "openTime" to (gym.openTime ?: "07:00"),
                "closeTime" to (gym.closeTime ?: "22:00"),
                "maxCancellationsAllowed" to (gym.maxCancellationsAllowed ?: 4)
            ))
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    @PutMapping("/branding/{gymId}")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'ADMIN', 'ROLE_SUPER_ADMIN', 'SUPER_ADMIN', 'PERM_MANAGE_USERS')")
    fun updateBranding(
        @PathVariable gymId: Long,
        @RequestBody request: GymBrandingUpdateRequest
    ): ResponseEntity<Any> {
        return try {
            val updatedGym = gymService.updateGymBranding(
                gymId = gymId,
                gymName = request.gymName,
                primaryColor = request.primaryColor,
                secondaryColor = request.secondaryColor,
                isGradient = request.isGradient,
                logoUrl = request.logoUrl,
                address = request.address,
                phone = request.phone,
                email = request.email,
                instagram = request.instagram,
                website = request.website,
                offeredLessonGroups = request.offeredLessonGroups
            )
            ResponseEntity.ok(mapOf(
                "message" to "Salon kurumsal kimliği ve iletişim bilgileri başarıyla güncellendi",
                "gymId" to updatedGym.id,
                "gymName" to updatedGym.name,
                "primaryColor" to updatedGym.primaryColor,
                "secondaryColor" to updatedGym.secondaryColor,
                "isGradient" to updatedGym.isGradient,
                "logoUrl" to updatedGym.logoUrl,
                "address" to updatedGym.address,
                "phone" to updatedGym.phone,
                "email" to updatedGym.email,
                "instagram" to updatedGym.instagram,
                "website" to updatedGym.website,
                "offeredLessonGroups" to (updatedGym.offeredLessonGroups ?: "PT,Pilates,Kickboks,Yoga")
            ))
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    @PutMapping("/working-hours/{gymId}")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN')")
    fun updateWorkingHours(
        @PathVariable gymId: Long,
        @RequestBody request: GymWorkingHoursRequest
    ): ResponseEntity<Any> {
        return try {
            val updatedGym = gymService.updateWorkingHours(gymId, request.workingDays, request.openTime, request.closeTime, request.maxCancellationsAllowed)
            ResponseEntity.ok(mapOf(
                "message" to "Salon çalışma saatleri başarıyla güncellendi",
                "workingDays" to updatedGym.workingDays,
                "openTime" to updatedGym.openTime,
                "closeTime" to updatedGym.closeTime,
                "maxCancellationsAllowed" to (updatedGym.maxCancellationsAllowed ?: 4)
            ))
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }
}
