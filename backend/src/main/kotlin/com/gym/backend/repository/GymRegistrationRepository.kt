package com.gym.backend.repository

import com.gym.backend.model.GymRegistration
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository

@Repository
interface GymRegistrationRepository : JpaRepository<GymRegistration, Long> {
    @Query("SELECT g FROM GymRegistration g WHERE g.gym.id = :gymId")
    fun findAllByGymId(@Param("gymId") gymId: Long): List<GymRegistration>

    @Query("SELECT g FROM GymRegistration g WHERE g.gym.id = :gymId AND g.isActive = true")
    fun findAllByGymIdAndIsActiveTrue(@Param("gymId") gymId: Long): List<GymRegistration>

    fun findFirstByGym_IdAndUser_IdOrderByRegisteredAtDesc(gymId: Long, userId: Long): GymRegistration?

    @Query("SELECT g FROM GymRegistration g WHERE g.user.id = :userId")
    fun findAllByUserId(@Param("userId") userId: Long): List<GymRegistration>

    @Query("SELECT g FROM GymRegistration g WHERE g.user.id IN :userIds")
    fun findAllByUserIdIn(@Param("userIds") userIds: List<Long>): List<GymRegistration>

    @Query("SELECT CASE WHEN COUNT(g) > 0 THEN true ELSE false END FROM GymRegistration g WHERE g.gym.id = :gymId AND g.user.id = :userId")
    fun existsByGymIdAndUserId(@Param("gymId") gymId: Long, @Param("userId") userId: Long): Boolean
}
