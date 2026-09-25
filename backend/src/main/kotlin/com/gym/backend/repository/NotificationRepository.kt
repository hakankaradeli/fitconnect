package com.gym.backend.repository

import com.gym.backend.model.Notification
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface NotificationRepository : JpaRepository<Notification, Long> {
    fun findAllByUserIdOrderByCreatedAtDesc(userId: Long): List<Notification>
}
