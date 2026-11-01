package com.gym.backend.repository

import com.gym.backend.model.User
import com.gym.backend.model.UserRole
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository

@Repository
interface UserRepository : JpaRepository<User, Long> {
    fun findByEmail(email: String): User?
    
    fun findAllByGymIdAndRole(gymId: Long, role: UserRole): List<User>
    
    @Query("SELECT u FROM User u WHERE u.gym.id = :gymId AND (u.isDeleted IS NULL OR u.isDeleted = false)")
    fun findAllByGymIdAndIsDeletedFalse(gymId: Long): List<User>

    @Query("SELECT u FROM User u WHERE u.gym.id = :gymId AND u.isDeleted = true")
    fun findAllByGymIdAndIsDeletedTrue(gymId: Long): List<User>

    @Query("SELECT u FROM User u WHERE u.gym.id = :gymId AND u.role = :role AND (u.isDeleted IS NULL OR u.isDeleted = false)")
    fun findAllByGymIdAndRoleAndIsDeletedFalse(gymId: Long, role: UserRole): List<User>
    
    @Query("SELECT u FROM User u WHERE u.gym IS NULL AND (u.isDeleted IS NULL OR u.isDeleted = false) ORDER BY u.id DESC")
    fun findAllUnassignedUsers(): List<User>

    @Query("SELECT u FROM User u WHERE u.id = :userId")
    fun findUserByIdSafely(userId: Long): User?
    
    fun findAllByAssignedTrainerId(trainerId: Long): List<User>

    @org.springframework.data.jpa.repository.Modifying
    @org.springframework.transaction.annotation.Transactional
    @Query(value = "ALTER TABLE users ALTER COLUMN profile_image_url TYPE TEXT", nativeQuery = true)
    fun alterProfileImageUrlColumnType()
}
