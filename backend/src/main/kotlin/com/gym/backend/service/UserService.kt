package com.gym.backend.service

import com.gym.backend.dto.UserCreateRequest
import com.gym.backend.model.User
import com.gym.backend.model.Notification
import com.gym.backend.model.LeaveRecord
import com.gym.backend.repository.*
import org.slf4j.LoggerFactory
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

@Service
class UserService(
    private val userRepository: UserRepository,
    private val gymRepository: GymRepository,
    private val bookingRepository: BookingRepository,
    private val notificationRepository: NotificationRepository,
    private val leaveRecordRepository: LeaveRecordRepository,
    private val memberCreditRepository: MemberCreditRepository,
    private val deletedUserArchiveRepository: com.gym.backend.repository.DeletedUserArchiveRepository,
    private val appRegistrationRepository: com.gym.backend.repository.AppRegistrationRepository,
    private val gymRegistrationRepository: com.gym.backend.repository.GymRegistrationRepository,
    private val entityManager: jakarta.persistence.EntityManager,
    private val passwordEncoder: PasswordEncoder
) {
    private val logger = LoggerFactory.getLogger(UserService::class.java)
    @Transactional
    fun createUser(request: UserCreateRequest): User {
        if (userRepository.findByEmail(request.email) != null) {
            throw Exception("Bu e-posta adresi zaten kullanımda!")
        }

        val gym = gymRepository.findById(request.gymId).orElseThrow { Exception("Salon bulunamadı!") }

        val newUser = User(
            email = request.email,
            fullName = request.fullName,
            passwordHash = passwordEncoder.encode(request.password.trim()),
            phone = request.phone,
            role = request.role,
            gym = gym
        )

        if (request.role == com.gym.backend.model.UserRole.MEMBER) {
            request.trainerId?.let {
                val trainer = userRepository.findById(it).orElseThrow { Exception("Atanan eğitmen bulunamadı!") }
                newUser.assignedTrainer = trainer
            }
            newUser.assignedLessonType = request.lessonType
        }

        if (request.role == com.gym.backend.model.UserRole.TRAINER) {
            newUser.canTeach = request.canTeach ?: mutableListOf()
        }

        val savedUser = userRepository.save(newUser)

        val regDate = savedUser.createdAt ?: java.time.LocalDateTime.now()
        appRegistrationRepository.save(com.gym.backend.model.AppRegistration(
            entityType = com.gym.backend.model.AppRegistrationEntityType.USER,
            userId = savedUser.id,
            gymId = gym.id,
            email = savedUser.email,
            fullNameOrTitle = savedUser.fullName,
            role = savedUser.role.name,
            registeredAt = regDate
        ))

        gymRegistrationRepository.save(com.gym.backend.model.GymRegistration(
            gym = gym,
            user = savedUser,
            role = savedUser.role,
            registeredAt = regDate,
            isActive = true
        ))

        if (savedUser.role == com.gym.backend.model.UserRole.MEMBER) {
            memberCreditRepository.save(com.gym.backend.model.MemberCredit(member = savedUser))
        }

        return savedUser
    }

    @Transactional
    fun updateMemberAssignment(memberId: Long, trainerId: Long?, lessonType: String?): User {
        val member = userRepository.findById(memberId).orElseThrow { Exception("Üye bulunamadı!") }
        
        if (trainerId != null) {
            val trainer = userRepository.findById(trainerId).orElseThrow { Exception("Atanan eğitmen bulunamadı!") }
            member.assignedTrainer = trainer
        } else {
            member.assignedTrainer = null
        }
        
        member.assignedLessonType = lessonType
        
        return userRepository.save(member)
    }

    @Transactional
    fun updateTrainerCanTeach(trainerId: Long, canTeach: List<String>): User {
        val trainer = userRepository.findById(trainerId).orElseThrow { Exception("Eğitmen bulunamadı!") }
        trainer.canTeach = canTeach.toMutableList()
        return userRepository.save(trainer)
    }

    @Transactional
    fun unfreezeMember(memberId: Long): User {
        val member = userRepository.findById(memberId).orElseThrow { Exception("Üye bulunamadı!") }
        member.freezeStart = null
        member.freezeEnd = null
        member.freezeReason = null
        
        notificationRepository.save(Notification(
            user = member,
            message = "Üyelik dondurma işleminiz sonlandırıldı. Tekrar hoş geldiniz!"
        ))

        return userRepository.save(member)
    }

    @Transactional
    fun freezeMember(memberId: Long, start: java.time.LocalDate, end: java.time.LocalDate, reason: String?): User {
        val member = userRepository.findById(memberId).orElseThrow { Exception("Üye bulunamadı!") }
        member.freezeStart = start
        member.freezeEnd = end
        member.freezeReason = reason

        val futureBookings = bookingRepository.findAllActiveByMemberIdAndStartTimeAfter(
            memberId, start.atStartOfDay()
        ).filter { it.startTime.isBefore(end.plusDays(1).atStartOfDay()) && it.status != "COMPLETED" && it.status != "CANCELLED" }

        val formatterDate = DateTimeFormatter.ofPattern("dd/MM/yyyy")
        val startStr = start.format(formatterDate)
        val endStr = end.format(formatterDate)

        val affectedTrainers = futureBookings.map { it.trainer }.distinctBy { it.id }

        futureBookings.forEach { booking ->
            booking.status = "CANCELLED"
            booking.cancellationReason = "Üyelik Dondurma: $reason"
            booking.cancellationDate = LocalDateTime.now()
            bookingRepository.save(booking)
        }

        affectedTrainers.forEach { trainer ->
            val message = "${member.fullName} adlı üyenin hesabı dondurulduğu için $startStr ile $endStr tarihleri arasındaki planlı dersleri otomatik iptal edilmiştir."
            notificationRepository.save(Notification(user = trainer, message = message))
        }

        val memberMsg = if (futureBookings.isNotEmpty()) {
            "Üyeliğiniz $startStr - $endStr tarihleri arasında dondurulmuştur ve bu aralıktaki planlı dersleriniz iptal edilmiştir."
        } else {
            "Üyeliğiniz $startStr - $endStr tarihleri arasında dondurulmuştur."
        }

        notificationRepository.save(Notification(
            user = member,
            message = memberMsg
        ))

        return userRepository.save(member)
    }

    fun enrichUsersWithRegistrationDates(users: List<User>, gymId: Long? = null) {
        if (users.isEmpty()) return
        val userIds = users.mapNotNull { it.id }
        if (userIds.isEmpty()) return

        val appRegs = appRegistrationRepository.findAllByUserIdIn(userIds).associateBy { it.userId }
        val gymRegs = if (gymId != null) {
            gymRegistrationRepository.findAllByGymId(gymId).groupBy { it.user.id }
        } else {
            gymRegistrationRepository.findAllByUserIdIn(userIds).groupBy { it.user.id }
        }

        users.forEach { u ->
            u.appRegistrationDate = appRegs[u.id]?.registeredAt ?: u.createdAt
            val userGymList = gymRegs[u.id]
            u.gymRegistrationDate = userGymList?.firstOrNull()?.registeredAt ?: u.createdAt
        }
    }

    fun getUsersByGym(gymId: Long): List<User> {
        logger.debug("Kullanıcı listesi talebi: GymId={}", gymId)
        val users = userRepository.findAllByGymIdAndIsDeletedFalse(gymId)
        enrichUsersWithRegistrationDates(users, gymId)
        logger.debug("Bulunan aktif kullanıcı sayısı: {}", users.size)
        return users
    }

    fun getUserById(userId: Long): User {
        val user = userRepository.findById(userId).orElseThrow { Exception("Kullanıcı bulunamadı!") }
        enrichUsersWithRegistrationDates(listOf(user), user.gym?.id)
        return user
    }

    @Transactional
    fun updateProfile(userId: Long, request: com.gym.backend.dto.UpdateProfileRequest): User {
        val user = userRepository.findById(userId).orElseThrow { Exception("Kullanıcı bulunamadı!") }
        
        if (!request.firstName.isNullOrBlank()) user.firstName = request.firstName
        if (!request.lastName.isNullOrBlank()) user.lastName = request.lastName
        
        if (user.firstName != null || user.lastName != null) {
            user.fullName = "${user.firstName ?: ""} ${user.lastName ?: ""}".trim()
        }
        
        if (!request.phone.isNullOrBlank()) user.phone = request.phone
        if (request.birthDate != null) user.birthDate = request.birthDate
        if (!request.gender.isNullOrBlank()) user.gender = request.gender
        
        user.profileImageUrl = request.profileImageUrl
        user.instagram = request.instagram
        user.linkedin = request.linkedin
        user.twitter = request.twitter

        if (!request.newPassword.isNullOrBlank()) {
            if (!request.currentPassword.isNullOrBlank()) {
                val isBcrypt = isBcryptHash(user.passwordHash)
                val currentMatches = if (isBcrypt) {
                    passwordEncoder.matches(request.currentPassword.trim(), user.passwordHash)
                } else {
                    user.passwordHash == request.currentPassword.trim()
                }
                if (!currentMatches) {
                    throw Exception("Mevcut şifreniz hatalı!")
                }
            }
            user.passwordHash = passwordEncoder.encode(request.newPassword.trim())
        }

        return userRepository.save(user)
    }

    fun getDeletedUsersByGym(gymId: Long): List<User> {
        val users = userRepository.findAllByGymIdAndIsDeletedTrue(gymId)
        enrichUsersWithRegistrationDates(users, gymId)
        return users
    }

    @jakarta.annotation.PostConstruct
    @Transactional
    fun repairMissingData() {
        try {
            try {
                userRepository.alterProfileImageUrlColumnType()
            } catch (e: Exception) {
            }

            val allUsers = userRepository.findAll()
            var repairCount = 0
            allUsers.forEach {
                try {
                    var updated = false
                    if (it.isActive == null) { it.isActive = true; updated = true }
                    if (it.isDeleted == null) { it.isDeleted = false; updated = true }
                    if (updated) {
                        userRepository.save(it)
                        repairCount++
                    }

                    if (it.role == com.gym.backend.model.UserRole.MEMBER) {
                        if (memberCreditRepository.findByMemberId(it.id!!) == null) {
                            memberCreditRepository.save(com.gym.backend.model.MemberCredit(member = it))
                        }
                    }
                } catch (e: Exception) {
                }
            }
            if (repairCount > 0) logger.info("Veri onarımı: {} kullanıcının eksik durum bilgileri tamamlandı.", repairCount)
        } catch (e: Exception) {
            logger.error("Veri onarımı sırasında hata oluştu: {}", e.message, e)
        }
    }

    @Transactional
    fun deleteUser(userId: Long, replacementTrainerId: Long? = null) {
        val user = userRepository.findById(userId).orElseThrow { Exception("Kullanıcı bulunamadı") }
        
        if (user.role == com.gym.backend.model.UserRole.MEMBER) {
            cancelFutureBookingsAndNotifyTrainers(user)
        } else if (user.role == com.gym.backend.model.UserRole.TRAINER) {
            reassignTrainerData(user, replacementTrainerId)
        }
        
        archiveAndDeleteUser(userId)
    }

    @Transactional
    fun archiveAndDeleteUser(userId: Long, ipAddress: String? = null, deviceInfo: String? = null) {
        val user = userRepository.findById(userId).orElse(null)
        if (user != null) {
            try {
                val archive = com.gym.backend.model.DeletedUserArchive(
                    originalUserId = user.id!!,
                    fullName = user.fullName,
                    email = user.email,
                    phone = user.phone,
                    role = user.role.name,
                    gymName = user.gym?.name,
                    deleteIpAddress = ipAddress,
                    deleteDeviceInfo = deviceInfo,
                    deletedAt = LocalDateTime.now(),
                    retentionPurgeDate = LocalDateTime.now().plusDays(200)
                )
                deletedUserArchiveRepository.save(archive)
            } catch (e: Exception) {
                logger.warn("Arşiv kaydı oluşturulurken uyarı: {}", e.message)
            }
        }
        deleteUnassignedUserPermanently(userId)
    }

    @Transactional
    fun deleteUnassignedUserPermanently(userId: Long) {
        val deleteStatements = listOf(
            "DELETE FROM user_consent_logs WHERE user_id = :userId",
            "DELETE FROM performed_exercises WHERE booking_id IN (SELECT id FROM bookings WHERE member_id = :userId OR trainer_id = :userId OR cancelled_by_id = :userId)",
            "DELETE FROM surveys WHERE booking_id IN (SELECT id FROM bookings WHERE member_id = :userId OR trainer_id = :userId OR cancelled_by_id = :userId)",
            "DELETE FROM accruals WHERE trainer_id = :userId OR booking_id IN (SELECT id FROM bookings WHERE member_id = :userId OR trainer_id = :userId OR cancelled_by_id = :userId)",
            "DELETE FROM bookings WHERE member_id = :userId OR trainer_id = :userId OR cancelled_by_id = :userId",
            "DELETE FROM installments WHERE member_id = :userId",
            "DELETE FROM notifications WHERE user_id = :userId",
            "DELETE FROM member_credits WHERE member_id = :userId",
            "DELETE FROM nutrition_plans WHERE member_id = :userId OR trainer_id = :userId",
            "DELETE FROM expenses WHERE trainer_id = :userId",
            "DELETE FROM trainer_rates WHERE trainer_id = :userId",
            "DELETE FROM workouts WHERE member_id = :userId OR trainer_id = :userId",
            "DELETE FROM temporary_permissions WHERE trainer_id = :userId OR user_id = :userId",
            "DELETE FROM leave_records WHERE trainer_id = :userId OR replacement_trainer_id = :userId",
            "DELETE FROM user_teach_types WHERE user_id = :userId",
            "DELETE FROM gym_registrations WHERE user_id = :userId",
            "UPDATE users SET assigned_trainer_id = NULL WHERE assigned_trainer_id = :userId OR id = :userId",
            "DELETE FROM users WHERE id = :userId"
        )

        try {
            for (sql in deleteStatements) {
                entityManager.createNativeQuery(sql)
                    .setParameter("userId", userId)
                    .executeUpdate()
            }
        } catch (e: Exception) {
            logger.warn("deleteUnassignedUserPermanently yürütme uyarısı: {}", e.message)
            try {
                entityManager.createNativeQuery("UPDATE users SET is_deleted = true, is_active = false, gym_id = NULL WHERE id = :userId")
                    .setParameter("userId", userId)
                    .executeUpdate()
            } catch (_: Exception) {}
        }
    }

    @Transactional
    fun toggleUserStatus(userId: Long, replacementTrainerId: Long? = null): User {
        val user = userRepository.findById(userId).orElseThrow { Exception("Kullanıcı bulunamadı") }
        user.isActive = !(user.isActive ?: true)
        
        if (user.isActive == false) {
            if (user.role == com.gym.backend.model.UserRole.MEMBER) {
                cancelFutureBookingsAndNotifyTrainers(user)
            } else if (user.role == com.gym.backend.model.UserRole.TRAINER) {
                reassignTrainerData(user, replacementTrainerId)
            }
        }
        
        return userRepository.save(user)
    }

    @Transactional
    fun setTrainerLeave(trainerId: Long, start: LocalDateTime, end: LocalDateTime, replacementTrainerId: Long?): User {
        val trainer = userRepository.findById(trainerId).orElseThrow { Exception("Eğitmen bulunamadı") }
        if (trainer.role != com.gym.backend.model.UserRole.TRAINER) throw Exception("Sadece eğitmenler için izin tanımlanabilir")

        trainer.leaveStart = start
        trainer.leaveEnd = end

        var replacementTrainer: User? = null
        if (replacementTrainerId != null) {
            replacementTrainer = userRepository.findById(replacementTrainerId).orElseThrow { Exception("Yedek eğitmen bulunamadı") }
            val formatter = DateTimeFormatter.ofPattern("dd/MM HH:mm")

            val bookingsToReassign = bookingRepository.findAllActiveByTrainerIdAndStartTimeBetween(
                trainerId, start, end
            ).filter { it.status != "CANCELLED" }

            bookingsToReassign.forEach { booking ->
                booking.trainer = replacementTrainer
                bookingRepository.save(booking)

                notificationRepository.save(Notification(
                    user = booking.member,
                    message = "Eğitmen İzni: ${trainer.fullName} izinli olduğu için ${booking.startTime.format(formatter)} dersiniz ${replacementTrainer.fullName} hocaya devredildi."
                ))
                notificationRepository.save(Notification(
                    user = replacementTrainer,
                    message = "İzin Devri: ${trainer.fullName} izinli olduğu için ${booking.member.fullName} ile olan ${booking.startTime.format(formatter)} dersi size atandı."
                ))
            }
        }

        leaveRecordRepository.save(LeaveRecord(
            trainer = trainer,
            startDate = start,
            endDate = end,
            replacementTrainer = replacementTrainer,
            status = "ACTIVE"
        ))

        return userRepository.save(trainer)
    }

    @Transactional
    fun cancelLeave(leaveId: Long) {
        val record = leaveRecordRepository.findById(leaveId).orElseThrow { Exception("İzin kaydı bulunamadı") }
        record.status = "CANCELLED"
        leaveRecordRepository.save(record)

        val trainer = record.trainer
        if (trainer.leaveStart == record.startDate && trainer.leaveEnd == record.endDate) {
            trainer.leaveStart = null
            trainer.leaveEnd = null
            userRepository.save(trainer)
        }
    }

    fun getTrainerLeaveHistory(trainerId: Long): List<LeaveRecord> {
        return leaveRecordRepository.findAllByTrainerIdOrderByStartDateDesc(trainerId)
    }

    private fun reassignTrainerData(oldTrainer: User, replacementTrainerId: Long?) {
        if (replacementTrainerId == null) return
        
        val newTrainer = userRepository.findById(replacementTrainerId)
            .orElseThrow { Exception("Yeni eğitmen bulunamadı") }

        val formatter = DateTimeFormatter.ofPattern("dd/MM HH:mm")

        val futureBookings = bookingRepository.findAllActiveByTrainerIdAndStartTimeAfter(
            oldTrainer.id!!, LocalDateTime.now()
        )

        futureBookings.forEach { booking ->
            val oldBookingTime = booking.startTime.format(formatter)
            
            booking.trainer = newTrainer
            bookingRepository.save(booking)

            notificationRepository.save(Notification(
                user = booking.member,
                message = "Eğitmen değişikliği: ${oldTrainer.fullName} yerine ${newTrainer.fullName} ile ${oldBookingTime} dersiniz güncellendi."
            ))

            notificationRepository.save(Notification(
                user = newTrainer,
                message = "Yeni ders atandı: ${oldTrainer.fullName} yerine ${booking.member.fullName} ile ${oldBookingTime} dersi size devredildi."
            ))
        }

        val assignedMembers = userRepository.findAllByAssignedTrainerId(oldTrainer.id)
        assignedMembers.forEach { member ->
            member.assignedTrainer = newTrainer
            userRepository.save(member)
            
            notificationRepository.save(Notification(
                user = member,
                message = "Sabit eğitmeniniz ${newTrainer.fullName} olarak güncellendi."
            ))
        }
    }

    private fun cancelFutureBookingsAndNotifyTrainers(member: User) {
        val futureBookings = bookingRepository.findAllActiveByMemberIdAndStartTimeAfter(
            member.id!!, LocalDateTime.now()
        )

        val formatter = DateTimeFormatter.ofPattern("dd/MM HH:mm")
        
        futureBookings.forEach { booking ->
            val message = "${member.fullName} isimli üye pasif/silindiği için ${booking.startTime.format(formatter)} dersi iptal edildi ve saati boşa çıktı."
            notificationRepository.save(Notification(user = booking.trainer, message = message))
            
            booking.status = "CANCELLED"
            booking.cancellationReason = "Kullanıcı pasif/silindi"
            booking.cancellationDate = LocalDateTime.now()
            bookingRepository.save(booking)
        }
    }

    @Transactional
    fun assignUserToGym(userId: Long, gymId: Long, roleStr: String? = null): User {
        val user = userRepository.findById(userId)
            .orElseThrow { Exception("Kullanıcı bulunamadı!") }
        val gym = gymRepository.findById(gymId)
            .orElseThrow { Exception("Spor salonu bulunamadı!") }

        user.gym = gym

        if (!roleStr.isNullOrBlank()) {
            try {
                val newRole = com.gym.backend.model.UserRole.valueOf(roleStr.uppercase())
                if (newRole == com.gym.backend.model.UserRole.MEMBER || newRole == com.gym.backend.model.UserRole.TRAINER) {
                    user.role = newRole
                }
            } catch (_: Exception) {
            }
        }

        val savedUser = userRepository.save(user)

        val regDate = java.time.LocalDateTime.now()
        val userIdVal = savedUser.id
        val gymIdVal = gym.id
        if (userIdVal != null && !appRegistrationRepository.existsByUserId(userIdVal)) {
            appRegistrationRepository.save(com.gym.backend.model.AppRegistration(
                entityType = com.gym.backend.model.AppRegistrationEntityType.USER,
                userId = userIdVal,
                gymId = gymIdVal,
                email = savedUser.email,
                fullNameOrTitle = savedUser.fullName,
                role = savedUser.role.name,
                registeredAt = savedUser.createdAt ?: regDate
            ))
        }

        if (userIdVal != null && gymIdVal != null && !gymRegistrationRepository.existsByGymIdAndUserId(gymIdVal, userIdVal)) {
            gymRegistrationRepository.save(com.gym.backend.model.GymRegistration(
                gym = gym,
                user = savedUser,
                role = savedUser.role,
                registeredAt = regDate,
                isActive = true
            ))
        }

        if (savedUser.role == com.gym.backend.model.UserRole.MEMBER && memberCreditRepository.findByMemberId(savedUser.id!!) == null) {
            memberCreditRepository.save(com.gym.backend.model.MemberCredit(member = savedUser, totalPurchased = 0, totalUsed = 0))
        }

        val roleTitle = if (savedUser.role == com.gym.backend.model.UserRole.MEMBER) "Üye" else "Eğitmen"
        notificationRepository.save(Notification(
            user = savedUser,
            message = "${gym.name} salonuna $roleTitle olarak kaydınız başarıyla tamamlandı! 🏋️‍♂️"
        ))

        return savedUser
    }

    @Transactional
    fun changeSuperAdminPassword(email: String, currentPassword: String, newPassword: String): User {
        val cleanEmail = email.trim().lowercase()
        val user = userRepository.findByEmail(cleanEmail)
            ?: userRepository.findAll().firstOrNull { it.email.trim().lowercase() == cleanEmail }
            ?: throw Exception("Süper yönetici hesabı bulunamadı!")

        if (user.role != com.gym.backend.model.UserRole.SUPER_ADMIN) {
            throw Exception("Bu işlem yalnızca Süper Yönetici için geçerlidir!")
        }

        val isBcrypt = isBcryptHash(user.passwordHash)
        val matches = if (isBcrypt) {
            passwordEncoder.matches(currentPassword.trim(), user.passwordHash)
        } else {
            user.passwordHash == currentPassword.trim()
        }

        if (!matches) {
            throw Exception("Mevcut şifreniz hatalı!")
        }

        user.passwordHash = passwordEncoder.encode(newPassword.trim())
        return userRepository.save(user)
    }

    fun getGymRegistrations(gymId: Long): List<com.gym.backend.model.GymRegistration> {
        return gymRegistrationRepository.findAllByGymId(gymId)
    }

    fun getAppRegistrations(gymId: Long? = null): List<com.gym.backend.model.AppRegistration> {
        return if (gymId != null) {
            appRegistrationRepository.findAllByGymId(gymId)
        } else {
            appRegistrationRepository.findAll()
        }
    }

    private fun isBcryptHash(hash: String?): Boolean {
        if (hash.isNullOrBlank()) return false
        return hash.startsWith("\$2a\$") || hash.startsWith("\$2b\$") || hash.startsWith("\$2y\$")
    }
}
