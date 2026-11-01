package com.gym.backend.service

import com.gym.backend.dto.GymCreateRequest
import com.gym.backend.dto.GymSummaryResponse
import com.gym.backend.model.Gym
import com.gym.backend.model.User
import com.gym.backend.model.UserRole
import com.gym.backend.repository.GymRepository
import com.gym.backend.repository.UserRepository
import jakarta.persistence.EntityManager
import org.slf4j.LoggerFactory
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
class GymService(
    private val gymRepository: GymRepository,
    private val userRepository: UserRepository,
    private val userService: UserService,
    private val appRegistrationRepository: com.gym.backend.repository.AppRegistrationRepository,
    private val gymRegistrationRepository: com.gym.backend.repository.GymRegistrationRepository,
    private val entityManager: EntityManager,
    private val passwordEncoder: PasswordEncoder
) {
    private val logger = LoggerFactory.getLogger(GymService::class.java)
    @Transactional
    fun createGymWithAdmin(request: GymCreateRequest): GymSummaryResponse {
        val cleanAdminEmail = request.adminEmail.trim().lowercase()
        val existingUser = userRepository.findByEmail(cleanAdminEmail)
        if (existingUser != null) {
            if (existingUser.isDeleted != true && existingUser.gym != null) {
                throw Exception("Bu e-posta adresi (${request.adminEmail}) zaten aktif bir salonda kullanımda!")
            }
        }

        val gym = Gym(
            name = request.gymName,
            address = request.address,
            logoUrl = request.logoUrl,
            primaryColor = request.primaryColor ?: "#3F51B5"
        )
        val savedGym = gymRepository.save(gym)

        val adminUser = if (existingUser != null && (existingUser.isDeleted == true || existingUser.gym == null)) {
            existingUser.fullName = request.adminFullName
            existingUser.phone = request.adminPhone
            existingUser.passwordHash = passwordEncoder.encode(request.adminPassword.trim())
            existingUser.role = UserRole.ADMIN
            existingUser.gym = savedGym
            existingUser.isActive = true
            existingUser.isDeleted = false
            existingUser.freezeStart = null
            existingUser.freezeEnd = null
            existingUser.freezeReason = null
            existingUser.leaveStart = null
            existingUser.leaveEnd = null
            existingUser.assignedTrainer = null
            existingUser.assignedLessonType = null
            userRepository.save(existingUser)
        } else {
            val newUser = User(
                email = cleanAdminEmail,
                passwordHash = passwordEncoder.encode(request.adminPassword.trim()),
                fullName = request.adminFullName,
                phone = request.adminPhone,
                role = UserRole.ADMIN,
                gym = savedGym
            )
            userRepository.save(newUser)
        }

        // Spor salonunun uygulamaya kayıt tarihi
        appRegistrationRepository.save(com.gym.backend.model.AppRegistration(
            entityType = com.gym.backend.model.AppRegistrationEntityType.GYM,
            gymId = savedGym.id,
            email = cleanAdminEmail,
            fullNameOrTitle = savedGym.name,
            role = "GYM",
            registeredAt = savedGym.createdAt
        ))

        // Salon yöneticisinin uygulamaya kayıt tarihi
        appRegistrationRepository.save(com.gym.backend.model.AppRegistration(
            entityType = com.gym.backend.model.AppRegistrationEntityType.USER,
            userId = adminUser.id,
            gymId = savedGym.id,
            email = adminUser.email,
            fullNameOrTitle = adminUser.fullName,
            role = "ADMIN",
            registeredAt = adminUser.createdAt ?: java.time.LocalDateTime.now()
        ))

        // Salon yöneticisinin salona kayıt tarihi
        gymRegistrationRepository.save(com.gym.backend.model.GymRegistration(
            gym = savedGym,
            user = adminUser,
            role = UserRole.ADMIN,
            registeredAt = adminUser.createdAt ?: java.time.LocalDateTime.now(),
            isActive = true
        ))

        return GymSummaryResponse(
            gymId = savedGym.id!!,
            gymName = savedGym.name,
            primaryColor = savedGym.primaryColor,
            logoUrl = savedGym.logoUrl,
            address = savedGym.address,
            isActive = savedGym.isActive ?: true,
            memberCount = 0,
            trainerCount = 0,
            adminEmail = adminUser.email,
            adminFullName = adminUser.fullName,
            adminPhone = adminUser.phone
        )
    }

    fun getAllGymSummaries(): List<GymSummaryResponse> {
        val gyms = gymRepository.findAll()
        return gyms.map { gym ->
            val gymId = gym.id ?: 0L
            val members = userRepository.findAllByGymIdAndRoleAndIsDeletedFalse(gymId, UserRole.MEMBER).size.toLong()
            val allUsers = userRepository.findAllByGymIdAndIsDeletedFalse(gymId)
            val trainers = allUsers.count { it.role == UserRole.TRAINER || it.role == UserRole.ADMIN || it.role == UserRole.SUPER_ADMIN || it.canTeach.isNotEmpty() }.toLong()
            val admins = userRepository.findAllByGymIdAndRoleAndIsDeletedFalse(gymId, UserRole.ADMIN)
            val admin = admins.firstOrNull()

            GymSummaryResponse(
                gymId = gymId,
                gymName = gym.name,
                primaryColor = gym.primaryColor,
                logoUrl = gym.logoUrl,
                address = gym.address,
                isActive = gym.isActive ?: true,
                memberCount = members,
                trainerCount = trainers,
                adminEmail = admin?.email,
                adminFullName = admin?.fullName,
                adminPhone = admin?.phone
            )
        }
    }

    @Transactional
    fun updateGymBranding(
        gymId: Long,
        gymName: String? = null,
        primaryColor: String? = null,
        secondaryColor: String? = null,
        isGradient: Boolean? = null,
        logoUrl: String? = null,
        address: String? = null,
        phone: String? = null,
        email: String? = null,
        instagram: String? = null,
        website: String? = null,
        offeredLessonGroups: String? = null
    ): Gym {
        val gym = gymRepository.findById(gymId).orElseThrow { Exception("Salon bulunamadı!") }
        if (!gymName.isNullOrBlank()) {
            gym.name = gymName
        }
        if (!primaryColor.isNullOrBlank()) {
            gym.primaryColor = primaryColor
        }
        if (!secondaryColor.isNullOrBlank()) {
            gym.secondaryColor = secondaryColor
        }
        if (isGradient != null) {
            gym.isGradient = isGradient
        }
        if (!logoUrl.isNullOrBlank()) {
            gym.logoUrl = logoUrl
        }
        if (address != null) gym.address = address
        if (phone != null) gym.phone = phone
        if (email != null) gym.email = email
        if (instagram != null) gym.instagram = instagram
        if (website != null) gym.website = website
        if (offeredLessonGroups != null) gym.offeredLessonGroups = offeredLessonGroups
        return gymRepository.save(gym)
    }

    @Transactional
    fun updateWorkingHours(gymId: Long, workingDays: String, openTime: String, closeTime: String, maxCancellationsAllowed: Int?): Gym {
        val gym = gymRepository.findById(gymId).orElseThrow { Exception("Salon bulunamadı!") }
        gym.workingDays = workingDays
        gym.openTime = openTime
        gym.closeTime = closeTime
        if (maxCancellationsAllowed != null) {
            gym.maxCancellationsAllowed = maxCancellationsAllowed
        }
        return gymRepository.save(gym)
    }

    fun getGymBranding(gymId: Long): Gym {
        return gymRepository.findById(gymId).orElseThrow { Exception("Salon bulunamadı!") }
    }

    @Transactional
    fun toggleGymStatus(gymId: Long): Gym {
        val gym = gymRepository.findById(gymId).orElseThrow { Exception("Salon bulunamadı!") }
        gym.isActive = !(gym.isActive ?: true)
        return gymRepository.save(gym)
    }

    @Transactional
    fun updateGymDetailsWithAdmin(
        gymId: Long, 
        name: String, 
        primaryColor: String?, 
        logoUrl: String?, 
        address: String?,
        adminFullName: String?,
        adminEmail: String?,
        adminPassword: String?,
        adminPhone: String?
    ): Gym {
        val gym = gymRepository.findById(gymId).orElseThrow { Exception("Salon bulunamadı!") }
        gym.name = name
        if (!primaryColor.isNullOrBlank()) gym.primaryColor = primaryColor
        if (logoUrl != null) gym.logoUrl = logoUrl
        gym.address = address

        val cleanEmail = adminEmail?.trim()?.lowercase()

        if (!cleanEmail.isNullOrBlank()) {
            val admins = userRepository.findAllByGymIdAndRoleAndIsDeletedFalse(gymId, UserRole.ADMIN)
            var admin = admins.firstOrNull()

            val existingUserWithEmail = userRepository.findByEmail(cleanEmail)

            if (admin == null) {
                if (existingUserWithEmail != null) {
                    admin = existingUserWithEmail
                } else {
                    val cleanPassword = adminPassword?.trim()?.ifBlank { "123456" } ?: "123456"
                    admin = User(
                        email = cleanEmail,
                        passwordHash = passwordEncoder.encode(cleanPassword),
                        fullName = adminFullName?.trim()?.ifBlank { name } ?: name,
                        phone = adminPhone?.trim()?.ifBlank { null },
                        role = UserRole.ADMIN,
                        gym = gym,
                        isActive = true,
                        isDeleted = false
                    )
                }
            }

            if (!adminFullName.isNullOrBlank()) admin.fullName = adminFullName.trim()
            admin.email = cleanEmail
            if (!adminPhone.isNullOrBlank()) admin.phone = adminPhone.trim()
            if (!adminPassword.isNullOrBlank()) admin.passwordHash = passwordEncoder.encode(adminPassword.trim())
            admin.gym = gym
            admin.role = UserRole.ADMIN
            admin.isDeleted = false
            admin.isActive = true
            userRepository.save(admin)
        }

        return gymRepository.save(gym)
    }

    @Transactional
    fun updateGymDetails(gymId: Long, name: String, primaryColor: String?, logoUrl: String?, address: String?): Gym {
        return updateGymDetailsWithAdmin(gymId, name, primaryColor, logoUrl, address, null, null, null, null)
    }

    @Transactional
    fun deleteGym(gymId: Long) {
        val gym = gymRepository.findById(gymId).orElseThrow { Exception("Salon bulunamadı!") }

        try {
            entityManager.createNativeQuery("UPDATE users SET role = 'MEMBER', gym_id = NULL, assigned_trainer_id = NULL WHERE gym_id = :gymId")
                .setParameter("gymId", gymId)
                .executeUpdate()

            entityManager.createNativeQuery("DELETE FROM accruals WHERE gym_id = :gymId").setParameter("gymId", gymId).executeUpdate()
            entityManager.createNativeQuery("DELETE FROM announcements WHERE gym_id = :gymId").setParameter("gymId", gymId).executeUpdate()
            entityManager.createNativeQuery("DELETE FROM expenses WHERE gym_id = :gymId").setParameter("gymId", gymId).executeUpdate()
            entityManager.createNativeQuery("DELETE FROM exercises WHERE gym_id = :gymId").setParameter("gymId", gymId).executeUpdate()
            entityManager.createNativeQuery("DELETE FROM temporary_permissions WHERE gym_id = :gymId").setParameter("gymId", gymId).executeUpdate()
            entityManager.createNativeQuery("DELETE FROM trainer_rates WHERE gym_id = :gymId").setParameter("gymId", gymId).executeUpdate()
            entityManager.createNativeQuery("DELETE FROM installments WHERE gym_id = :gymId").setParameter("gymId", gymId).executeUpdate()
            entityManager.createNativeQuery("DELETE FROM surveys WHERE gym_id = :gymId").setParameter("gymId", gymId).executeUpdate()
            entityManager.createNativeQuery("DELETE FROM gym_registrations WHERE gym_id = :gymId").setParameter("gymId", gymId).executeUpdate()

            entityManager.createNativeQuery("DELETE FROM performed_exercises WHERE booking_id IN (SELECT id FROM bookings WHERE gym_id = :gymId)").setParameter("gymId", gymId).executeUpdate()
            entityManager.createNativeQuery("DELETE FROM bookings WHERE gym_id = :gymId").setParameter("gymId", gymId).executeUpdate()
        } catch (e: Exception) {
            logger.warn("Salon bağımlılıkları temizlenirken uyarı: {}", e.message)
        }

        gymRepository.delete(gym)
    }

    fun getSaasStats(): Map<String, Any> {
        val totalGyms = gymRepository.count()
        val totalUsers = userRepository.findAll().count { it.isDeleted != true }
        val activeGyms = gymRepository.findAll().count { it.isActive ?: true }

        return mapOf(
            "totalGyms" to totalGyms,
            "activeGyms" to activeGyms,
            "totalUsers" to totalUsers
        )
    }
}
