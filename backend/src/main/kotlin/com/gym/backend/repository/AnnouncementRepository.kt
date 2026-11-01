package com.gym.backend.repository

import com.gym.backend.model.Announcement
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface AnnouncementRepository : JpaRepository<Announcement, Long> {
    fun findAllByGymIdOrderByCreatedAtDesc(gymId: Long): List<Announcement>
}
