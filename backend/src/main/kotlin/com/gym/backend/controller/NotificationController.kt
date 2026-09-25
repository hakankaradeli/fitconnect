package com.gym.backend.controller

import com.gym.backend.repository.NotificationRepository
import com.gym.backend.service.NotificationService
import com.gym.backend.model.UserRole
import org.springframework.http.ResponseEntity
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/notifications")
class NotificationController(
    private val notificationRepository: NotificationRepository,
    private val notificationService: NotificationService
) {

    @GetMapping("/{userId}")
    @PreAuthorize("hasAnyAuthority('ROLE_TRAINER', 'ROLE_ADMIN', 'ROLE_MEMBER')")
    fun getNotifications(@PathVariable userId: Long): ResponseEntity<Any> {
        return ResponseEntity.ok(notificationRepository.findAllByUserIdOrderByCreatedAtDesc(userId))
    }

    @PutMapping("/mark-as-read/{id}")
    fun markAsRead(@PathVariable id: Long): ResponseEntity<Any> {
        val notification = notificationRepository.findById(id).orElseThrow { Exception("Bildirim bulunamadı") }
        notification.isRead = true
        notificationRepository.save(notification)
        return ResponseEntity.ok(mapOf("message" to "Okundu işaretlendi"))
    }

    @PostMapping("/send-bulk")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'PERM_MANAGE_USERS')")
    fun sendBulk(
        @RequestParam gymId: Long,
        @RequestParam message: String,
        @RequestParam(required = false) role: String?
    ): ResponseEntity<Any> {
        val userRole = role?.let { UserRole.valueOf(it.uppercase()) }
        notificationService.sendBulkNotification(gymId, message, userRole)
        return ResponseEntity.ok(mapOf("message" to "Bildirimler başarıyla gönderildi"))
    }
}
