package com.gym.backend.service

import com.gym.backend.model.PermissionType
import com.gym.backend.model.TemporaryPermission
import com.gym.backend.repository.TemporaryPermissionRepository
import com.gym.backend.repository.UserRepository
import com.gym.backend.repository.GymRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime

@Service
class DelegationService(
    private val permissionRepository: TemporaryPermissionRepository,
    private val userRepository: UserRepository,
    private val gymRepository: GymRepository
) {
    @Transactional
    fun delegatePermission(
        trainerId: Long,
        gymId: Long,
        permissionType: PermissionType,
        startTime: LocalDateTime,
        endTime: LocalDateTime
    ): TemporaryPermission {
        val trainer = userRepository.findById(trainerId).orElseThrow { Exception("Eğitmen bulunamadı") }
        val gym = gymRepository.findById(gymId).orElseThrow { Exception("Salon bulunamadı") }

        val newPermission = TemporaryPermission(
            trainer = trainer,
            permission = permissionType,
            startTime = startTime,
            endTime = endTime,
            gym = gym
        )

        return permissionRepository.save(newPermission)
    }

    fun getActivePermissions(email: String): List<PermissionType> {
        return permissionRepository.findActivePermissionsByUser(email, LocalDateTime.now())
            .map { it.permission }
    }

    fun getAllDelegationsInGym(gymId: Long): List<TemporaryPermission> {
        return permissionRepository.findAllByGymId(gymId)
    }

    @Transactional
    fun revokePermission(permissionId: Long) {
        permissionRepository.deleteById(permissionId)
    }
}
