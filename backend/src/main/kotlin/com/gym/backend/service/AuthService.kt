package com.gym.backend.service

import com.gym.backend.dto.*
import com.gym.backend.model.Gym
import com.gym.backend.model.MemberCredit
import com.gym.backend.model.User
import com.gym.backend.model.UserRole
import com.gym.backend.repository.GymRepository
import com.gym.backend.repository.MemberCreditRepository
import com.gym.backend.repository.UserRepository
import org.slf4j.LoggerFactory
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
class AuthService(
    private val userRepository: UserRepository,
    private val gymRepository: GymRepository,
    private val memberCreditRepository: MemberCreditRepository,
    private val jwtService: JwtService,
    private val delegationService: DelegationService,
    private val userService: UserService,
    private val userConsentLogRepository: com.gym.backend.repository.UserConsentLogRepository,
    private val appRegistrationRepository: com.gym.backend.repository.AppRegistrationRepository,
    private val gymRegistrationRepository: com.gym.backend.repository.GymRegistrationRepository,
    private val passwordEncoder: PasswordEncoder
) {
    private val logger = LoggerFactory.getLogger(AuthService::class.java)

    private fun maskEmail(email: String): String {
        val atIndex = email.indexOf('@')
        if (atIndex <= 1) return "***@***"
        val prefix = email.substring(0, minOf(2, atIndex))
        val domain = email.substring(atIndex)
        return "$prefix***$domain"
    }
    fun getPublicGyms(): List<PublicGymResponse> {
        return gymRepository.findAll()
            .filter { it.isActive ?: true }
            .map { PublicGymResponse(gymId = it.id!!, gymName = it.name, logoUrl = it.logoUrl, primaryColor = it.primaryColor) }
    }

    @Transactional
    fun register(request: RegisterRequest): LoginResponse {
        val cleanEmail = request.email.trim().lowercase()
        val cleanName = request.fullName.trim()
        val cleanPassword = request.password.trim()

        if (cleanEmail.isBlank() || cleanName.isBlank() || cleanPassword.isBlank()) {
            throw Exception("Lütfen tüm alanları eksiksiz doldurun.")
        }

        val existingUser = userRepository.findByEmail(cleanEmail)
        if (existingUser != null) {
            if (existingUser.isDeleted != true) {
                if (existingUser.isActive == false) {
                    throw Exception("Bu e-posta adresi ile pasif durumda bir hesap bulunmaktadır. Lütfen yöneticinizle iletişime geçin.")
                } else {
                    throw Exception("Bu e-posta adresi ($cleanEmail) zaten başka bir hesap tarafından kullanılıyor.")
                }
            }
        }

        val targetGym = if (request.gymId != null && request.gymId > 0) {
            gymRepository.findById(request.gymId).orElse(null)
        } else null

        val gym = targetGym

        val targetRole = request.role ?: UserRole.MEMBER

        val nameParts = cleanName.split(" ")
        val firstName = nameParts.firstOrNull() ?: cleanName
        val lastName = if (nameParts.size > 1) nameParts.subList(1, nameParts.size).joinToString(" ") else ""

        val savedUser = if (existingUser != null && existingUser.isDeleted == true) {
            existingUser.fullName = cleanName
            existingUser.firstName = firstName
            existingUser.lastName = lastName
            existingUser.passwordHash = passwordEncoder.encode(cleanPassword)
            existingUser.phone = request.phone?.trim()?.ifBlank { null }
            existingUser.role = targetRole
            existingUser.gym = gym
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
                email = cleanEmail,
                passwordHash = passwordEncoder.encode(cleanPassword),
                fullName = cleanName,
                firstName = firstName,
                lastName = lastName,
                phone = request.phone?.trim()?.ifBlank { null },
                role = targetRole,
                gym = gym
            )
            userRepository.save(newUser)
        }

        val consentLog = com.gym.backend.model.UserConsentLog(
            user = savedUser,
            userEmail = savedUser.email,
            userFullName = savedUser.fullName,
            termsAccepted = request.termsAccepted ?: true,
            healthDataConsentAccepted = request.healthDataConsentAccepted ?: true,
            marketingConsentAccepted = request.marketingConsentAccepted ?: false,
            ipAddress = request.ipAddress,
            deviceInfo = request.deviceInfo,
            createdAt = java.time.LocalDateTime.now()
        )
        userConsentLogRepository.save(consentLog)

        appRegistrationRepository.save(com.gym.backend.model.AppRegistration(
            entityType = com.gym.backend.model.AppRegistrationEntityType.USER,
            userId = savedUser.id,
            gymId = savedUser.gym?.id,
            email = savedUser.email,
            fullNameOrTitle = savedUser.fullName,
            role = targetRole.name,
            registeredAt = savedUser.createdAt ?: java.time.LocalDateTime.now(),
            ipAddress = request.ipAddress,
            deviceInfo = request.deviceInfo
        ))

        if (savedUser.gym != null) {
            gymRegistrationRepository.save(com.gym.backend.model.GymRegistration(
                gym = savedUser.gym!!,
                user = savedUser,
                role = targetRole,
                registeredAt = savedUser.createdAt ?: java.time.LocalDateTime.now(),
                isActive = true
            ))
        }

        if (targetRole == UserRole.MEMBER) {
            val existingCredit = memberCreditRepository.findByMemberId(savedUser.id!!)
            if (existingCredit != null) {
                existingCredit.totalPurchased = 0
                existingCredit.totalUsed = 0
                memberCreditRepository.save(existingCredit)
            } else {
                memberCreditRepository.save(MemberCredit(member = savedUser, totalPurchased = 0, totalUsed = 0))
            }
        }

        return authenticate(LoginRequest(email = cleanEmail, password = cleanPassword))
    }

    @Transactional
    fun authenticate(request: LoginRequest): LoginResponse {
        val cleanEmail = request.email.trim().lowercase()
        logger.info("Giriş denemesi alındı (Kullanıcı: {})", maskEmail(cleanEmail))

        var user = userRepository.findByEmail(cleanEmail)
            ?: userRepository.findAll().firstOrNull { it.email.trim().lowercase() == cleanEmail }

        if (user == null || user.isDeleted == true) {
            throw Exception("Kullanıcı bulunamadı!")
        }

        val rawPassword = request.password.trim()
        val isBcrypt = isBcryptHash(user.passwordHash)
        val passwordMatches = if (isBcrypt) {
            passwordEncoder.matches(rawPassword, user.passwordHash)
        } else {
            user.passwordHash == rawPassword
        }

        if (!passwordMatches) {
            throw Exception("Hatalı şifre!")
        }

        if (!isBcrypt) {
            user.passwordHash = passwordEncoder.encode(rawPassword)
            user = userRepository.save(user)
        }

        if (user.isActive == false) {
            throw Exception("Hesabınız pasif durumdadır. Lütfen yönetici ile iletişime geçin.")
        }

        if (user.gym == null && user.role != UserRole.SUPER_ADMIN) {
            if (user.role != UserRole.MEMBER) {
                user.role = UserRole.MEMBER
                user = userRepository.save(user)
            }
        }

        val token = jwtService.generateToken(user.email, user.role.name)
        val refreshToken = jwtService.generateRefreshToken(user.email)

        val assignedTrainerData: Map<String, Any>? = user.assignedTrainer?.let {
            mapOf<String, Any>(
                "id" to it.id!!,
                "fullName" to it.fullName
            )
        }

        val tempPermissions = delegationService.getActivePermissions(user.email).map { it.name }

        val isDefaultGym = user.gym == null || user.gym?.name == "Ana Sistem Salonu"

        return LoginResponse(
            token = token,
            refreshToken = refreshToken,
            userId = user.id!!,
            fullName = user.fullName,
            email = user.email,
            phone = user.phone,
            firstName = user.firstName,
            lastName = user.lastName,
            birthDate = user.birthDate?.toString(),
            gender = user.gender,
            role = user.role.name,
            gymId = if (isDefaultGym) 0L else (user.gym?.id ?: 0L),
            gymName = if (isDefaultGym) "" else (user.gym?.name ?: ""),
            primaryColor = user.gym?.primaryColor ?: "#3F51B5",
            secondaryColor = user.gym?.secondaryColor ?: "#00BFA5",
            isGradient = user.gym?.isGradient ?: false,
            offeredLessonGroups = user.gym?.offeredLessonGroups ?: "PT,Pilates,Kickboks,Yoga",
            openTime = user.gym?.openTime ?: "07:00",
            closeTime = user.gym?.closeTime ?: "22:00",
            workingDays = user.gym?.workingDays ?: "1,2,3,4,5,6",
            logoUrl = user.gym?.logoUrl,
            assignedTrainer = assignedTrainerData,
            tempPermissions = tempPermissions,
            profileImageUrl = user.profileImageUrl,
            instagram = user.instagram,
            linkedin = user.linkedin,
            twitter = user.twitter
        )
    }

    private fun isBcryptHash(hash: String?): Boolean {
        if (hash.isNullOrBlank()) return false
        return hash.startsWith("\$2a\$") || hash.startsWith("\$2b\$") || hash.startsWith("\$2y\$")
    }

    fun refreshToken(refreshToken: String): RefreshTokenResponse {
        val email = jwtService.validateRefreshToken(refreshToken)
            ?: throw Exception("Geçersiz veya süresi dolmuş refresh token!")

        val user = userRepository.findByEmail(email)
            ?: throw Exception("Kullanıcı bulunamadı!")

        if (user.isDeleted == true || user.isActive == false) {
            throw Exception("Kullanıcı hesabı aktif değil!")
        }

        val newAccessToken = jwtService.generateToken(user.email, user.role.name)
        val newRefreshToken = jwtService.generateRefreshToken(user.email)

        return RefreshTokenResponse(token = newAccessToken, refreshToken = newRefreshToken)
    }
}
