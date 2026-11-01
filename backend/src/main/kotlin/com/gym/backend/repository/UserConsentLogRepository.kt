package com.gym.backend.repository

import com.gym.backend.model.UserConsentLog
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface UserConsentLogRepository : JpaRepository<UserConsentLog, Long> {
    fun findAllByUserEmailOrderByCreatedAtDesc(email: String): List<UserConsentLog>
    fun findFirstByUserIdOrderByCreatedAtAsc(userId: Long): UserConsentLog?
}
