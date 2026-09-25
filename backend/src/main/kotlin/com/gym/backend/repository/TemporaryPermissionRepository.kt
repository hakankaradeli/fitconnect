package com.gym.backend.repository

import com.gym.backend.model.TemporaryPermission
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository
import java.time.LocalDateTime

@Repository
interface TemporaryPermissionRepository : JpaRepository<TemporaryPermission, Long> {
    
    @Query("SELECT tp FROM TemporaryPermission tp WHERE tp.trainer.email = :email AND :now BETWEEN tp.startTime AND tp.endTime")
    fun findActivePermissionsByUser(email: String, now: LocalDateTime): List<TemporaryPermission>

    fun findAllByGymId(gymId: Long): List<TemporaryPermission>
    
    fun findAllByTrainerId(trainerId: Long): List<TemporaryPermission>
}
