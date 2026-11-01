package com.gym.backend.repository

import com.gym.backend.model.AppRegistration
import com.gym.backend.model.AppRegistrationEntityType
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface AppRegistrationRepository : JpaRepository<AppRegistration, Long> {
    fun findByUserId(userId: Long): AppRegistration?
    fun findByGymIdAndEntityType(gymId: Long, entityType: AppRegistrationEntityType): AppRegistration?
    fun findAllByUserIdIn(userIds: List<Long>): List<AppRegistration>
    fun findAllByGymId(gymId: Long): List<AppRegistration>
    fun existsByUserId(userId: Long): Boolean
    fun existsByGymIdAndEntityType(gymId: Long, entityType: AppRegistrationEntityType): Boolean
}
