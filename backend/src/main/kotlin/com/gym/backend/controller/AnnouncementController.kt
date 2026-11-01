package com.gym.backend.controller

import com.gym.backend.config.GlobalExceptionHandler
import com.gym.backend.dto.AnnouncementCreateRequest
import com.gym.backend.service.AnnouncementService
import org.springframework.http.ResponseEntity
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/announcements")
class AnnouncementController(private val announcementService: AnnouncementService) {

    @PostMapping("/create")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'PERM_MANAGE_USERS')")
    fun createAnnouncement(@RequestBody request: AnnouncementCreateRequest): ResponseEntity<Any> {
        return try {
            val announcement = announcementService.createAnnouncement(request)
            ResponseEntity.ok(announcement)
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    @GetMapping("/gym/{gymId}")
    @PreAuthorize("hasAnyAuthority('ROLE_MEMBER', 'ROLE_TRAINER', 'ROLE_ADMIN')")
    fun getAnnouncements(@PathVariable gymId: Long): ResponseEntity<Any> {
        return ResponseEntity.ok(announcementService.getAnnouncementsByGym(gymId))
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'PERM_MANAGE_USERS')")
    fun deleteAnnouncement(@PathVariable id: Long): ResponseEntity<Any> {
        return try {
            announcementService.deleteAnnouncement(id)
            ResponseEntity.ok(mapOf("message" to "Duyuru silindi"))
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }
}
