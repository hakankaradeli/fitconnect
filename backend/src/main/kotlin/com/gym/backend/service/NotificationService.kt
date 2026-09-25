package com.gym.backend.service

import com.gym.backend.model.Notification
import com.gym.backend.model.UserRole
import com.gym.backend.repository.NotificationRepository
import com.gym.backend.repository.UserRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
class NotificationService(
    private val notificationRepository: NotificationRepository,
    private val userRepository: UserRepository
) {
    @Transactional
    fun sendBulkNotification(gymId: Long, message: String, role: UserRole? = null) {
        val users = if (role != null) {
            userRepository.findAllByGymIdAndRoleAndIsDeletedFalse(gymId, role)
        } else {
            userRepository.findAllByGymIdAndIsDeletedFalse(gymId)
        }

        users.forEach { user ->
            notificationRepository.save(Notification(user = user, message = message))
        }
    }
}
