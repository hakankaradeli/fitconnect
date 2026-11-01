package com.gym.backend.controller

import com.gym.backend.config.GlobalExceptionHandler
import com.gym.backend.dto.GymCreateRequest
import com.gym.backend.repository.UserRepository
import com.gym.backend.service.GymService
import com.gym.backend.service.UserService
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/super-admin")
class SuperAdminController(
    private val gymService: GymService,
    private val userService: UserService,
    private val userRepository: UserRepository,
    private val userConsentLogRepository: com.gym.backend.repository.UserConsentLogRepository,
    private val deletedUserArchiveRepository: com.gym.backend.repository.DeletedUserArchiveRepository
) {

    @PostMapping("/gyms/create")
    fun createGym(@RequestBody request: GymCreateRequest): ResponseEntity<Any> {
        return try {
            val response = gymService.createGymWithAdmin(request)
            ResponseEntity.ok(response)
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    @GetMapping("/gyms/list")
    fun listGyms(): ResponseEntity<Any> {
        return ResponseEntity.ok(gymService.getAllGymSummaries())
    }

    @PutMapping("/gyms/toggle-status/{gymId}")
    fun toggleGymStatus(@PathVariable gymId: Long): ResponseEntity<Any> {
        return try {
            val gym = gymService.toggleGymStatus(gymId)
            ResponseEntity.ok(gym)
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    @PutMapping("/gyms/{gymId}")
    fun updateGym(
        @PathVariable gymId: Long,
        @RequestBody request: Map<String, String?>
    ): ResponseEntity<Any> {
        return try {
            val name = request["gymName"] ?: throw Exception("Salon adı boş olamaz")
            val primaryColor = request["primaryColor"]
            val logoUrl = request["logoUrl"]
            val address = request["address"]
            val adminFullName = request["adminFullName"]
            val adminEmail = request["adminEmail"]
            val adminPassword = request["adminPassword"]
            val adminPhone = request["adminPhone"]

            val gym = gymService.updateGymDetailsWithAdmin(
                gymId, name, primaryColor, logoUrl, address,
                adminFullName, adminEmail, adminPassword, adminPhone
            )
            ResponseEntity.ok(gym)
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    @DeleteMapping("/gyms/{gymId}")
    fun deleteGym(@PathVariable gymId: Long): ResponseEntity<Any> {
        return try {
            gymService.deleteGym(gymId)
            ResponseEntity.ok(mapOf("message" to "Salon ve bağlı verileri silindi."))
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    @GetMapping("/stats")
    fun getStats(): ResponseEntity<Any> {
        return ResponseEntity.ok(gymService.getSaasStats())
    }

    @GetMapping("/unassigned-users")
    fun getUnassignedUsers(): ResponseEntity<Any> {
        val users = userRepository.findAllUnassignedUsers()
        val response = users.map { user ->
            mapOf(
                "id" to user.id,
                "fullName" to user.fullName,
                "email" to user.email,
                "phone" to user.phone,
                "role" to user.role.name
            )
        }
        return ResponseEntity.ok(response)
    }

    @DeleteMapping("/users/{userId}")
    fun deleteUnassignedUser(
        @PathVariable userId: Long,
        servletRequest: jakarta.servlet.http.HttpServletRequest
    ): ResponseEntity<Any> {
        return try {
            val xForwardedFor = servletRequest.getHeader("X-Forwarded-For")
            val clientIp = if (!xForwardedFor.isNullOrBlank()) xForwardedFor.split(",").first().trim() else servletRequest.remoteAddr
            val userAgent = servletRequest.getHeader("User-Agent")

            userService.archiveAndDeleteUser(userId, clientIp, userAgent)
            ResponseEntity.ok(mapOf("message" to "Kullanıcı başarıyla silindi ve 200 günlük arşive kaldırıldı."))
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    @GetMapping("/consent-logs")
    fun getConsentLogs(): ResponseEntity<Any> {
        val logs = userConsentLogRepository.findAll()
        val response = logs.map { log ->
            mapOf(
                "id" to log.id,
                "userEmail" to log.userEmail,
                "userFullName" to log.userFullName,
                "termsAccepted" to log.termsAccepted,
                "healthDataConsentAccepted" to log.healthDataConsentAccepted,
                "marketingConsentAccepted" to log.marketingConsentAccepted,
                "ipAddress" to (log.ipAddress ?: "Bilinmiyor"),
                "deviceInfo" to (log.deviceInfo ?: "Bilinmiyor"),
                "createdAt" to log.createdAt.toString()
            )
        }
        return ResponseEntity.ok(response)
    }

    @GetMapping("/audit-reports")
    fun getAuditReports(): ResponseEntity<Any> {
        val consentLogs = userConsentLogRepository.findAll()
        val deletedArchives = deletedUserArchiveRepository.findAllByOrderByDeletedAtDesc()

        return ResponseEntity.ok(mapOf(
            "consentLogs" to consentLogs.map { log ->
                mapOf(
                    "id" to log.id,
                    "type" to "KAYIT",
                    "userEmail" to log.userEmail,
                    "userFullName" to log.userFullName,
                    "ipAddress" to (log.ipAddress ?: "Bilinmiyor"),
                    "deviceInfo" to (log.deviceInfo ?: "Bilinmiyor"),
                    "termsAccepted" to log.termsAccepted,
                    "healthDataConsentAccepted" to log.healthDataConsentAccepted,
                    "marketingConsentAccepted" to log.marketingConsentAccepted,
                    "createdAt" to log.createdAt.toString()
                )
            },
            "deletedArchives" to deletedArchives.map { archive ->
                mapOf(
                    "id" to archive.id,
                    "type" to "SİLİNME",
                    "originalUserId" to archive.originalUserId,
                    "userFullName" to archive.fullName,
                    "userEmail" to archive.email,
                    "phone" to (archive.phone ?: ""),
                    "role" to archive.role,
                    "gymName" to (archive.gymName ?: "Salonsuz"),
                    "deleteIpAddress" to (archive.deleteIpAddress ?: "Bilinmiyor"),
                    "deleteDeviceInfo" to (archive.deleteDeviceInfo ?: "Bilinmiyor"),
                    "deletedAt" to archive.deletedAt.toString(),
                    "retentionPurgeDate" to archive.retentionPurgeDate.toString()
                )
            }
        ))
    }

    @PostMapping("/change-password")
    fun changePassword(
        @RequestBody request: Map<String, String>,
        authentication: org.springframework.security.core.Authentication?
    ): ResponseEntity<Any> {
        return try {
            val email = authentication?.name ?: request["email"] ?: throw Exception("Kullanıcı kimliği doğrulanamadı")
            val currentPassword = request["currentPassword"]?.trim() ?: throw Exception("Mevcut şifre zorunludur")
            val newPassword = request["newPassword"]?.trim() ?: throw Exception("Yeni şifre zorunludur")
            if (newPassword.length < 6) {
                throw Exception("Yeni şifre en az 6 karakter olmalıdır")
            }
            userService.changeSuperAdminPassword(email, currentPassword, newPassword)
            ResponseEntity.ok(mapOf("message" to "Şifreniz başarıyla güncellendi"))
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }
}
