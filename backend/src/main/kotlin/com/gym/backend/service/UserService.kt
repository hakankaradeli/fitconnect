package com.gym.backend.service

import com.gym.backend.dto.UserCreateRequest
import com.gym.backend.model.User
import com.gym.backend.model.Notification
import com.gym.backend.model.LeaveRecord
import com.gym.backend.repository.*
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
    private val memberCreditRepository: MemberCreditRepository
) {
    @Transactional
    fun createUser(request: UserCreateRequest): User {
        if (userRepository.findByEmail(request.email) != null) {
            throw Exception("Bu e-posta adresi zaten kullanımda!")
        }

        val gym = gymRepository.findById(request.gymId).orElseThrow { Exception("Salon bulunamadı!") }

        val newUser = User(
            email = request.email,
            fullName = request.fullName,
            passwordHash = request.password, // Not: BCrypt kullanılmalı
            phone = request.phone,
            role = request.role,
            gym = gym
        )

        // Üye ise eğitmen ve ders tipi ata
        if (request.role == com.gym.backend.model.UserRole.MEMBER) {
            request.trainerId?.let {
                val trainer = userRepository.findById(it).orElseThrow { Exception("Atanan eğitmen bulunamadı!") }
                newUser.assignedTrainer = trainer
            }
            newUser.assignedLessonType = request.lessonType
        }

        // Eğitmen ise verebildiği dersleri ata
        if (request.role == com.gym.backend.model.UserRole.TRAINER) {
            newUser.canTeach = request.canTeach ?: mutableListOf()
        }

        val savedUser = userRepository.save(newUser)

        // Üye ise kredi hesabını da oluştur
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
        
        notificationRepository.save(Notification(
            user = member,
            message = "Üyeliğiniz $start - $end tarihleri arasında dondurulmuştur."
        ))

        return userRepository.save(member)
    }

    fun getUsersByGym(gymId: Long): List<User> {
        println("Liste talebi: GymId=$gymId")
        val users = userRepository.findAllByGymIdAndIsDeletedFalse(gymId)
        println("Bulunan aktif kullanıcı sayısı: ${users.size}")
        return users
    }

    fun getUserById(userId: Long): User {
        return userRepository.findById(userId).orElseThrow { Exception("Kullanıcı bulunamadı!") }
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

        // Şifre Değiştirme
        if (!request.newPassword.isNullOrBlank()) {
            if (!request.currentPassword.isNullOrBlank() && user.passwordHash != request.currentPassword) {
                throw Exception("Mevcut şifreniz hatalı!")
            }
            user.passwordHash = request.newPassword
        }

        return userRepository.save(user)
    }

    fun getDeletedUsersByGym(gymId: Long): List<User> {
        return userRepository.findAllByGymIdAndIsDeletedTrue(gymId)
    }

    @jakarta.annotation.PostConstruct
    @Transactional
    fun repairMissingData() {
        try {
            // PostgreSQL tablosundaki VARCHAR(255) kolonunu TEXT olarak güncelle
            try {
                userRepository.alterProfileImageUrlColumnType()
            } catch (e: Exception) {
                // Kolon tipi zaten TEXT ise devam et
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

                    // Kredi hesabı eksik olan üyeleri tamamla
                    if (it.role == com.gym.backend.model.UserRole.MEMBER) {
                        if (memberCreditRepository.findByMemberId(it.id!!) == null) {
                            memberCreditRepository.save(com.gym.backend.model.MemberCredit(member = it))
                        }
                    }
                } catch (e: Exception) {
                }
            }
            if (repairCount > 0) println("--- VERI ONARIMI: $repairCount kullanıcının eksik durum bilgileri tamamlandı. ---")
        } catch (e: Exception) {
            println("--- KRITIK UYARI: Veri onarımı sırasında hata oluştu: ${e.message} ---")
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
        
        user.isDeleted = true
        user.isActive = false
        userRepository.save(user)
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

            // İzinli olduğu dönemdeki dersleri bul
            val bookingsToReassign = bookingRepository.findAllActiveByTrainerIdAndStartTimeBetween(
                trainerId, start, end
            ).filter { it.status != "CANCELLED" }

            bookingsToReassign.forEach { booking ->
                booking.trainer = replacementTrainer
                bookingRepository.save(booking)

                // Bildirimler
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

        // İzin kaydını geçmişe ekle
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
        // Eğer bu aktif izin ise User üzerindeki alanları temizle
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

        // 1. Eğitmenin gelecekteki derslerini aktar
        val futureBookings = bookingRepository.findAllActiveByTrainerIdAndStartTimeAfter(
            oldTrainer.id!!, LocalDateTime.now()
        )

        futureBookings.forEach { booking ->
            val oldBookingTime = booking.startTime.format(formatter)
            
            // Dersi güncelle
            booking.trainer = newTrainer
            bookingRepository.save(booking)

            // Üyeye bildirim
            notificationRepository.save(Notification(
                user = booking.member,
                message = "Eğitmen değişikliği: ${oldTrainer.fullName} yerine ${newTrainer.fullName} ile ${oldBookingTime} dersiniz güncellendi."
            ))

            // Yeni eğitmene bildirim
            notificationRepository.save(Notification(
                user = newTrainer,
                message = "Yeni ders atandı: ${oldTrainer.fullName} yerine ${booking.member.fullName} ile ${oldBookingTime} dersi size devredildi."
            ))
        }

        // 2. Eğitmenin sabit üyelerini aktar
        val assignedMembers = userRepository.findAllByAssignedTrainerId(oldTrainer.id!!)
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
            // Eğitmene bildirim oluştur
            val message = "${member.fullName} isimli üye pasif/silindiği için ${booking.startTime.format(formatter)} dersi iptal edildi ve saati boşa çıktı."
            notificationRepository.save(Notification(user = booking.trainer, message = message))
            
            // Dersi iptal et (silme, status guncelle)
            booking.status = "CANCELLED"
            booking.cancellationReason = "Kullanıcı pasif/silindi"
            booking.cancellationDate = LocalDateTime.now()
            bookingRepository.save(booking)
        }
    }
}
