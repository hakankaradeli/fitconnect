package com.gym.backend.service

import com.gym.backend.dto.AnnouncementCreateRequest
import com.gym.backend.model.Announcement
import com.gym.backend.model.Notification
import com.gym.backend.repository.AnnouncementRepository
import com.gym.backend.repository.GymRepository
import com.gym.backend.repository.NotificationRepository
import com.gym.backend.repository.UserRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
class AnnouncementService(
    private val announcementRepository: AnnouncementRepository,
    private val gymRepository: GymRepository,
    private val userRepository: UserRepository,
    private val notificationRepository: NotificationRepository
) {
    @Transactional
    fun createAnnouncement(request: AnnouncementCreateRequest): Announcement {
        val gym = gymRepository.findById(request.gymId).orElseThrow { Exception("Salon bulunamadı!") }
        
        val announcement = Announcement(
            gym = gym,
            title = request.title,
            content = request.content,
            imageUrl = request.imageUrl,
            targetRole = request.targetRole ?: "ALL"
        )

        val saved = announcementRepository.save(announcement)

        // İlgili hedef kitleye bildirim de gönder
        val roleEnum = when (request.targetRole?.uppercase()) {
            "MEMBER" -> com.gym.backend.model.UserRole.MEMBER
            "TRAINER" -> com.gym.backend.model.UserRole.TRAINER
            else -> null
        }

        val targetUsers = if (roleEnum != null) {
            userRepository.findAllByGymIdAndRoleAndIsDeletedFalse(request.gymId, roleEnum)
        } else {
            userRepository.findAllByGymIdAndIsDeletedFalse(request.gymId)
        }

        val notificationMsg = "Yeni Duyuru/Etkinlik: ${request.title}"
        targetUsers.forEach { user ->
            notificationRepository.save(Notification(user = user, message = notificationMsg))
        }

        return saved
    }

    fun getAnnouncementsByGym(gymId: Long): List<Announcement> {
        return announcementRepository.findAllByGymIdOrderByCreatedAtDesc(gymId)
    }

    @Transactional
    fun deleteAnnouncement(id: Long) {
        announcementRepository.deleteById(id)
    }
}
