package com.gym.backend.service

import com.gym.backend.model.Booking
import com.gym.backend.model.User
import com.gym.backend.model.PerformedExercise
import com.gym.backend.model.Notification
import com.gym.backend.repository.BookingRepository
import com.gym.backend.repository.UserRepository
import com.gym.backend.repository.PerformedExerciseRepository
import com.gym.backend.repository.NotificationRepository
import com.gym.backend.dto.PerformedExerciseRequest
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.DayOfWeek
import java.time.Duration
import java.time.LocalDateTime

@Service
class BookingService(
    private val bookingRepository: BookingRepository,
    private val userRepository: UserRepository,
    private val accrualService: AccrualService,
    private val financeService: FinanceService,
    private val performedExerciseRepository: PerformedExerciseRepository,
    private val notificationRepository: NotificationRepository
) {
    @Transactional
    fun addPerformedExercises(bookingId: Long, exercises: List<PerformedExerciseRequest>): Booking {
        val booking = bookingRepository.findById(bookingId).orElseThrow { Exception("Randevu bulunamadı!") }
        
        // Önce eskileri temizle (Üzerine yazma mantığı için)
        val existing = performedExerciseRepository.findAllByBookingId(bookingId)
        performedExerciseRepository.deleteAll(existing)

        exercises.forEach { req ->
            val performed = PerformedExercise(
                booking = booking,
                exerciseName = req.exerciseName,
                sets = req.sets,
                reps = req.reps,
                weight = req.weight,
                notes = req.notes
            )
            performedExerciseRepository.save(performed)
        }
        
        return bookingRepository.findById(bookingId).get()
    }
    @Transactional
    fun createBooking(memberId: Long, trainerId: Long, gymId: Long, startTime: LocalDateTime): Booking {
        val member = userRepository.findById(memberId).orElseThrow { Exception("Üye bulunamadı") }
        val now = LocalDateTime.now()

        // --- PRD KURALLARI ---

        // 1. Pazar Günü Kuralı
        if (startTime.dayOfWeek == DayOfWeek.SUNDAY) {
            throw Exception("Pazar günleri salon kapalıdır.")
        }

        // 2. Çalışma Saatleri Kuralı (07:00 - 22:00, son ders başlangıcı 21:00)
        if (startTime.hour < 7 || startTime.hour > 21) {
            throw Exception("Randevular sadece 07:00 - 21:00 başlangıçlı olabilir.")
        }

        // 3. 24 Saat Kuralı
        if (Duration.between(now, startTime).toHours() < 24) {
            throw Exception("Randevu en geç 24 saat önceden alınmalıdır.")
        }

        // 4. Kapasite Kontrolü (Max 4 Kişi)
        val currentParticipants = bookingRepository.countActiveBookings(gymId, startTime)
        if (currentParticipants >= 4) {
            throw Exception("Bu saat dilimi doludur (Maksimum 4 kişi).")
        }

        val newBooking = Booking(
            member = member,
            trainer = userRepository.findById(trainerId).orElseThrow { Exception("Eğitmen bulunamadı") },
            gym = member.gym,
            startTime = startTime,
            endTime = startTime.plusHours(1),
            status = "PENDING"
        )

        return bookingRepository.save(newBooking)
    }

    @Transactional
    fun verifyAndCompleteLesson(bookingId: Long, trainerId: Long): String {
        val booking = bookingRepository.findById(bookingId)
            .orElseThrow { Exception("Randevu bulunamadı!") }

        if (booking.trainer.id != trainerId) {
            throw Exception("Bu dersi başlatma yetkiniz yok!")
        }

        if (booking.status == "COMPLETED") {
            throw Exception("Bu ders zaten tamamlanmış.")
        }

        booking.status = "COMPLETED"
        bookingRepository.save(booking)

        val earning = accrualService.calculateTrainerEarning(booking.trainer.id!!, "PT Bireysel")
        accrualService.saveAccrual(booking.trainer, booking.gym, booking, earning)

        // Üye Kredisinden Düş
        financeService.deductCreditForSession(booking.member.id!!)

        // Taraf Bildirimleri
        notificationRepository.save(Notification(
            user = booking.member,
            message = "Ders başlamıştır, iyi dersler! 🏋️‍♂️"
        ))

        notificationRepository.save(Notification(
            user = booking.trainer,
            message = "${booking.member.fullName} ile ders başlamıştır, iyi dersler! 🏋️‍♂️"
        ))

        return "Ders başlamıştır, iyi dersler! 🏋️‍♂️"
    }

    @Transactional
    fun proposeBookingChange(bookingId: Long, newStartTime: LocalDateTime, isByAdmin: Boolean = true): Booking {
        val booking = bookingRepository.findById(bookingId).orElseThrow { Exception("Randevu bulunamadı!") }
        booking.startTime = newStartTime
        booking.endTime = newStartTime.plusHours(1)
        booking.status = if (isByAdmin) "PROPOSED" else "PENDING"
        return bookingRepository.save(booking)
    }

    @Transactional
    fun approveBooking(bookingId: Long): Booking {
        val booking = bookingRepository.findById(bookingId).orElseThrow { Exception("Randevu bulunamadı!") }
        booking.status = "ACTIVE"
        val saved = bookingRepository.save(booking)

        val formatter = java.time.format.DateTimeFormatter.ofPattern("dd/MM HH:mm")
        val dateStr = booking.startTime.format(formatter)

        notificationRepository.save(Notification(
            user = booking.member,
            message = "$dateStr tarihindeki dersiniz onaylandı ve programınıza eklendi."
        ))
        notificationRepository.save(Notification(
            user = booking.trainer,
            message = "${booking.member.fullName} ile $dateStr dersiniz onaylandı."
        ))

        return saved
    }

    @Transactional
    fun changeBookingTrainer(bookingId: Long, newTrainerId: Long, isByAdmin: Boolean = false): Booking {
        val booking = bookingRepository.findById(bookingId).orElseThrow { Exception("Randevu bulunamadı!") }
        val newTrainer = userRepository.findById(newTrainerId).orElseThrow { Exception("Yeni eğitmen bulunamadı!") }
        booking.trainer = newTrainer
        booking.status = if (isByAdmin) "PROPOSED" else "PENDING"
        return bookingRepository.save(booking)
    }

    @Transactional
    fun rejectBooking(bookingId: Long, cancelledById: Long? = null, reason: String? = null): Booking {
        val booking = bookingRepository.findById(bookingId).orElseThrow { Exception("Randevu bulunamadı!") }
        val cancellingUser = cancelledById?.let { userRepository.findById(it).orElse(null) }

        val hour = booking.startTime.hour
        val isPeak = hour in 7..10 || hour in 18..21

        // Üye iptal ediyorsa ve Yoğun Saatte 4 İptal Kotasını Aşmışsa -> Yönetici Onayına Sevk Et
        if (cancellingUser != null && cancellingUser.role == com.gym.backend.model.UserRole.MEMBER && isPeak) {
            val peakCancels = bookingRepository.countMemberPeakCancellations(cancellingUser.id!!)
            if (peakCancels >= 4) {
                booking.status = "PENDING_ADMIN_APPROVAL"
                booking.cancellationReason = "Yoğun saat 4 iptal kotası aşıldı. Kredi iadesi için yönetici onayı bekleniyor."
                val saved = bookingRepository.save(booking)

                val formatter = java.time.format.DateTimeFormatter.ofPattern("dd/MM HH:mm")
                val message = "${booking.member.fullName} üyesinin ${booking.startTime.format(formatter)} yoğun saat ders iptal kotası (4 iptal) dolmuştur. Kredi yakılması/iadesi için onayınız bekleniyor."

                val admins = userRepository.findAllByGymIdAndRoleAndIsDeletedFalse(booking.gym.id!!, com.gym.backend.model.UserRole.ADMIN)
                admins.forEach { admin ->
                    notificationRepository.save(Notification(user = admin, message = message))
                }

                notificationRepository.save(Notification(
                    user = booking.member,
                    message = "Yoğun saat iptal kotanız (4 iptal) dolduğu için iptal ve kredi iade talebiniz yönetici onayına sunulmuştur."
                ))

                return saved
            }
        }

        booking.status = "CANCELLED"
        booking.cancelledBy = cancellingUser
        booking.cancellationReason = reason
        booking.cancellationDate = LocalDateTime.now()
        
        val saved = bookingRepository.save(booking)

        val dateFormatter = java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy")
        val timeFormatter = java.time.format.DateTimeFormatter.ofPattern("HH:mm")
        val dateStr = booking.startTime.format(dateFormatter)
        val timeStr = booking.startTime.format(timeFormatter)

        // 1. Üyeye tam istenen formatta bildirim oluştur
        val memberMsg = if (cancellingUser != null && cancellingUser.id == booking.member.id) {
            "$dateStr Tarih ve saat $timeStr için randevu talep ettiğiniz dersiniz iptal edilmiştir."
        } else {
            "$dateStr Tarih ve saat $timeStr için randevu talep ettiğiniz dersiniz, eğitmeniniz ve salon yöneticisi onayı ile iptal edilmiştir. Lütfen yeni bir ders randevusu alınız."
        }
        notificationRepository.save(Notification(user = booking.member, message = memberMsg))

        // 2. Eğitmene bildirim oluştur (Eğer iptal eden eğitmen kendisi değilse)
        if (cancellingUser == null || cancellingUser.id != booking.trainer.id) {
            val trainerMsg = "${booking.member.fullName} üyesinin $dateStr $timeStr tarihindeki dersi yönetici tarafından kesin iptal edildi."
            notificationRepository.save(Notification(user = booking.trainer, message = trainerMsg))
        }

        return saved
    }

    @Transactional
    fun trainerRejectBooking(bookingId: Long, trainerId: Long, reason: String? = null): Booking {
        val booking = bookingRepository.findById(bookingId).orElseThrow { Exception("Randevu bulunamadı!") }
        
        // Üyenin randevusunu eğitmen reddederse yönetici onayına düşer
        booking.status = "PENDING_ADMIN_APPROVAL"
        booking.cancellationReason = reason ?: "Eğitmen tarafından reddedildi, yönetici onayı bekleniyor."
        val saved = bookingRepository.save(booking)

        val formatter = java.time.format.DateTimeFormatter.ofPattern("dd/MM HH:mm")
        val message = "Eğitmen ${booking.trainer.fullName}, ${booking.member.fullName} üyesinin ${booking.startTime.format(formatter)} randevusunu reddetti. Yönetici onayı bekleniyor."

        val admins = userRepository.findAllByGymIdAndRoleAndIsDeletedFalse(booking.gym.id!!, com.gym.backend.model.UserRole.ADMIN)
        admins.forEach { admin ->
            notificationRepository.save(Notification(user = admin, message = message))
        }

        notificationRepository.save(Notification(
            user = booking.member,
            message = "Randevunuz eğitmen tarafından incelendi ve yönetici onayına sevk edildi."
        ))

        return saved
    }

    fun getAdminPendingBookings(gymId: Long): List<Booking> {
        return bookingRepository.findAllByGymIdAndStatusOrderByStartTimeAsc(gymId, "PENDING_ADMIN_APPROVAL")
    }

    @Transactional
    fun confirmAttendance(bookingId: Long, willAttend: Boolean): Booking {
        val booking = bookingRepository.findById(bookingId).orElseThrow { Exception("Randevu bulunamadı!") }
        val formatter = java.time.format.DateTimeFormatter.ofPattern("dd/MM HH:mm")
        val dateStr = booking.startTime.format(formatter)

        if (!willAttend) {
            notificationRepository.save(Notification(
                user = booking.trainer,
                message = "${booking.member.fullName} üyesi $dateStr dersine katılamayacağını bildirdi."
            ))
            notificationRepository.save(Notification(
                user = booking.member,
                message = "$dateStr dersi katılım teyidinde 'Katılamayacağım' olarak yanıtlandığınız bildirildi."
            ))
        } else {
            notificationRepository.save(Notification(
                user = booking.member,
                message = "$dateStr dersi katılım teyidiniz başarıyla alındı. İyi antrenmanlar!"
            ))
        }

        return booking
    }

    fun getBookingById(bookingId: Long): Booking {
        return bookingRepository.findById(bookingId).orElseThrow { Exception("Randevu bulunamadı!") }
    }

    fun getMostCancelledMember(): List<Map<String, Any>> = bookingRepository.findTopCancelledMembers()
    fun getMostCancelledTrainerByOthers(): List<Map<String, Any>> = bookingRepository.findTopCancelledTrainersByOthers()
    fun getMostCancellingTrainer(): List<Map<String, Any>> = bookingRepository.findTopCancellingTrainers()

    fun getPendingTrainerBookings(trainerId: Long): List<Booking> = bookingRepository.findAllByTrainerIdAndStatus(trainerId, "PENDING")
    fun getMemberBookings(memberId: Long): List<Booking> = bookingRepository.findAllActiveByMemberId(memberId)
    fun getTrainerSchedule(trainerId: Long, start: LocalDateTime, end: LocalDateTime): List<Booking> = bookingRepository.findAllActiveByTrainerIdAndStartTimeBetween(trainerId, start, end)

    fun getAvailableSlots(trainerId: Long, gymId: Long, date: java.time.LocalDate): List<com.gym.backend.dto.SlotAvailability> {
        val slots = mutableListOf<com.gym.backend.dto.SlotAvailability>()
        val startHour = 7
        val endHour = 22

        for (hour in startHour until endHour) {
            val startTime = date.atTime(hour, 0)
            val trainer = userRepository.findById(trainerId).get()
            val isOnLeave = trainer.leaveStart != null && trainer.leaveEnd != null &&
                           !startTime.isBefore(trainer.leaveStart) && !startTime.isAfter(trainer.leaveEnd)

            val gymParticipants = bookingRepository.countActiveBookings(gymId, startTime)
            val isTrainerBusy = bookingRepository.findAllActiveByTrainerIdAndStartTimeBetween(trainerId, startTime, startTime.plusMinutes(59)).isNotEmpty()

            val isAvailable = !gymParticipants.let { it >= 4 } && !isTrainerBusy && !isOnLeave
            val reason = when {
                isOnLeave -> "Eğitmen İzinli"
                isTrainerBusy -> "Eğitmen Meşgul"
                gymParticipants >= 4 -> "Salon Dolu"
                else -> null
            }
            slots.add(com.gym.backend.dto.SlotAvailability(startTime, isAvailable, reason, gymParticipants))
        }
        return slots
    }

    @Transactional
    fun createBulkBookings(memberId: Long, trainerId: Long, gymId: Long, startTimes: List<LocalDateTime>): List<Booking> {
        return startTimes.map { createBooking(memberId, trainerId, gymId, it) }
    }

    fun getAvailableTrainersForSlot(gymId: Long, startTime: LocalDateTime): List<User> {
        val allTrainers = userRepository.findAllByGymIdAndRoleAndIsDeletedFalse(gymId, com.gym.backend.model.UserRole.TRAINER)
        return allTrainers.filter { trainer ->
            val isOnLeave = trainer.leaveStart != null && trainer.leaveEnd != null &&
                           !startTime.isBefore(trainer.leaveStart) && !startTime.isAfter(trainer.leaveEnd)
            val isBusy = bookingRepository.findAllActiveByTrainerIdAndStartTimeBetween(trainer.id!!, startTime, startTime.plusMinutes(59)).isNotEmpty()
            !isOnLeave && !isBusy
        }
    }
}
