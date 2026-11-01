package com.gym.backend.service

import com.gym.backend.dto.PerformedExerciseRequest
import com.gym.backend.dto.SlotAvailability
import com.gym.backend.model.Booking
import com.gym.backend.model.Gym
import com.gym.backend.model.Notification
import com.gym.backend.model.PerformedExercise
import com.gym.backend.model.User
import com.gym.backend.model.UserRole
import com.gym.backend.repository.BookingRepository
import com.gym.backend.repository.GymRepository
import com.gym.backend.repository.NotificationRepository
import com.gym.backend.repository.PerformedExerciseRepository
import com.gym.backend.repository.UserRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Duration
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.time.format.TextStyle
import java.util.Locale

@Service
class BookingService(
    private val bookingRepository: BookingRepository,
    private val userRepository: UserRepository,
    private val gymRepository: GymRepository,
    private val accrualService: AccrualService,
    private val financeService: FinanceService,
    private val performedExerciseRepository: PerformedExerciseRepository,
    private val notificationRepository: NotificationRepository
) {
    @Transactional
    fun addPerformedExercises(bookingId: Long, exercises: List<PerformedExerciseRequest>): Booking {
        val booking = bookingRepository.findById(bookingId).orElseThrow { Exception("Randevu bulunamadı!") }
        
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
    fun createBooking(memberId: Long, trainerId: Long, gymId: Long, startTime: LocalDateTime, ignoreRules: Boolean = false): Booking {
        val member = userRepository.findById(memberId).orElseThrow { Exception("Üye bulunamadı") }
        val now = LocalDateTime.now()

        if (member.freezeStart != null && member.freezeEnd != null) {
            val startDay = startTime.toLocalDate()
            if (!startDay.isBefore(member.freezeStart) && !startDay.isAfter(member.freezeEnd)) {
                throw Exception("Üyenin hesabı bu tarihler arasında dondurulmuştur. Ders atanamaz.")
            }
        }

        val targetGym = member.gym ?: gymRepository.findById(gymId).orElseThrow { Exception("Salon bulunamadı") }
        val workingDays = (targetGym.workingDays ?: "1,2,3,4,5,6").split(",").mapNotNull { it.toIntOrNull() }

        val dayOfWeekValue = startTime.dayOfWeek.value
        if (!workingDays.contains(dayOfWeekValue)) {
            val dayName = startTime.dayOfWeek.getDisplayName(TextStyle.FULL, Locale.forLanguageTag("tr-TR"))
            throw Exception("Salon $dayName günü kapalıdır.")
        }

        val openHour = (targetGym.openTime ?: "07:00").split(":").first().toIntOrNull() ?: 7
        val closeHour = (targetGym.closeTime ?: "22:00").split(":").first().toIntOrNull() ?: 22

        if (startTime.hour < openHour || startTime.hour > closeHour - 1) {
            val openStr = String.format("%02d:00", openHour)
            val closeStr = String.format("%02d:00", closeHour - 1)
            throw Exception("Randevular sadece $openStr - $closeStr başlangıçlı olabilir.")
        }

        if (!ignoreRules) {
            if (Duration.between(now, startTime).toHours() < 24) {
                throw Exception("Randevu en geç 24 saat önceden alınmalıdır.")
            }

            val currentParticipants = bookingRepository.countActiveBookings(gymId, startTime)
            if (currentParticipants >= 4) {
                throw Exception("Bu saat dilimi doludur (Maksimum 4 kişi).")
            }
        }

        val isTrainerBusy = bookingRepository.findAllActiveByTrainerIdAndStartTimeBetween(
            trainerId,
            startTime,
            startTime.plusMinutes(59)
        ).isNotEmpty()

        if (isTrainerBusy) {
            val formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")
            throw Exception("Eğitmenin ${startTime.format(formatter)} tarihindeki dersi ile çakıştığı için planlama yapılamamıştır.")
        }

        val trainer = userRepository.findById(trainerId).orElseThrow { Exception("Eğitmen bulunamadı") }

        val newBooking = Booking(
            member = member,
            trainer = trainer,
            gym = targetGym,
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
    fun startDirectLesson(trainerId: Long, memberId: Long, lessonType: String? = null): Booking {
        val trainer = userRepository.findById(trainerId).orElseThrow { Exception("Eğitmen bulunamadı!") }
        val member = userRepository.findById(memberId).orElseThrow { Exception("Üye bulunamadı!") }

        if (member.isDeleted == true || member.isActive == false) {
            throw Exception("Üye hesabı aktif değil!")
        }

        val now = LocalDateTime.now()
        if (member.freezeStart != null && member.freezeEnd != null) {
            val today = now.toLocalDate()
            if (!today.isBefore(member.freezeStart) && !today.isAfter(member.freezeEnd)) {
                throw Exception("Üyenin hesabı dondurulmuştur. Ders başlatılamaz.")
            }
        }

        financeService.deductCreditForSession(member.id!!)

        val gym = trainer.gym ?: member.gym ?: throw Exception("Salon bilgisi bulunamadı!")
        val effectiveLessonType = lessonType ?: member.assignedLessonType ?: "PT Bireysel"

        val booking = Booking(
            member = member,
            trainer = trainer,
            gym = gym,
            startTime = now,
            endTime = now.plusHours(1),
            status = "COMPLETED"
        )
        val savedBooking = bookingRepository.save(booking)

        val earning = accrualService.calculateTrainerEarning(trainer.id!!, effectiveLessonType)
        accrualService.saveAccrual(trainer, gym, savedBooking, earning)

        notificationRepository.save(Notification(
            user = member,
            message = "${trainer.fullName} ile ders başlamıştır. 1 seans krediniz düşülmüştür. İyi dersler! 🏋️‍♂️"
        ))
        notificationRepository.save(Notification(
            user = trainer,
            message = "${member.fullName} ile rezervasyonsuz ders başlamıştır. 1 seans kredisi düşülmüştür. İyi dersler! 🏋️‍♂️"
        ))

        return savedBooking
    }

    fun findMemberByEmail(email: String): User? {
        return userRepository.findByEmail(email)
    }

    fun getLatestCompletedSession(trainerId: Long, since: LocalDateTime): Booking? {
        return bookingRepository.findLatestCompletedSessions(trainerId, since).firstOrNull()
    }

    @Transactional
    fun refundCompletedBooking(bookingId: Long): Booking {
        val booking = bookingRepository.findById(bookingId).orElseThrow { Exception("Randevu bulunamadı!") }
        if (booking.status != "COMPLETED" && booking.status != "NO_SHOW" && booking.status != "ACTIVE" && booking.status != "PENDING" && booking.status != "PENDING_ADMIN_APPROVAL") {
            throw Exception("Bu ders durumu (${booking.status}) için iade işlemi yapılamaz.")
        }

        // Dersi iptal et ve üyeye 1 adet ders kredisini kesin olarak iade et
        financeService.refundCreditForSession(booking.member.id!!)
        accrualService.deleteAccrualByBooking(bookingId)

        booking.status = "CANCELLED"
        booking.cancellationReason = "Yönetici tarafından üyenin katılamadığı ders iptal edilerek kredi iade edildi."
        booking.cancellationDate = LocalDateTime.now()

        val formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")
        notificationRepository.save(Notification(
            user = booking.member,
            message = "Yönetici tarafından ${booking.startTime.format(formatter)} tarihindeki dersiniz iptal edilmiş ve 1 seans krediniz hesabınıza iade edilmiştir."
        ))
        notificationRepository.save(Notification(
            user = booking.trainer,
            message = "Yönetici tarafından ${booking.member.fullName} ile olan ${booking.startTime.format(formatter)} dersinin iptal ve iade işlemi yapılmıştır."
        ))

        return bookingRepository.save(booking)
    }

    @Transactional
    fun proposeBookingChange(bookingId: Long, newStartTime: LocalDateTime, isByAdmin: Boolean = true): Booking {
        val booking = bookingRepository.findById(bookingId).orElseThrow { Exception("Randevu bulunamadı!") }
        val member = booking.member
        if (member.freezeStart != null && member.freezeEnd != null) {
            val startDay = newStartTime.toLocalDate()
            if (!startDay.isBefore(member.freezeStart) && !startDay.isAfter(member.freezeEnd)) {
                throw Exception("Üyenin hesabı bu tarihler arasında dondurulmuştur. Değişiklik yapılamaz.")
            }
        }

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

        val formatter = DateTimeFormatter.ofPattern("dd/MM HH:mm")
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
        val maxAllowed = booking.gym.maxCancellationsAllowed ?: 4

        // Üye iptal ediyorsa ve Yoğun Saatte İptal Kotasını Aşmışsa -> Yönetici Onayına Sevk Et
        if (cancellingUser != null && cancellingUser.role == UserRole.MEMBER && isPeak) {
            val peakCancels = bookingRepository.countMemberPeakCancellations(cancellingUser.id!!)
            if (peakCancels >= maxAllowed) {
                booking.status = "PENDING_ADMIN_APPROVAL"
                booking.cancellationReason = "Yoğun saat $maxAllowed iptal kotası aşıldı. Kredi iadesi için yönetici onayı bekleniyor."
                val saved = bookingRepository.save(booking)

                val formatter = DateTimeFormatter.ofPattern("dd/MM HH:mm")
                val message = "${booking.member.fullName} üyesinin ${booking.startTime.format(formatter)} yoğun saat ders iptal kotası ($maxAllowed iptal) dolmuştur. Kredi yakılması/iadesi için onayınız bekleniyor."

                val admins = userRepository.findAllByGymIdAndRoleAndIsDeletedFalse(booking.gym.id!!, UserRole.ADMIN)
                admins.forEach { admin ->
                    notificationRepository.save(Notification(user = admin, message = message))
                }

                notificationRepository.save(Notification(
                    user = booking.member,
                    message = "Yoğun saat iptal kotanız ($maxAllowed iptal) dolduğu için iptal ve kredi iade talebiniz yönetici onayına sunulmuştur."
                ))

                return saved
            }
        }

        val wasProcessed = booking.status == "COMPLETED" || booking.status == "NO_SHOW"
        if (wasProcessed) {
            try {
                financeService.refundCreditForSession(booking.member.id!!)
            } catch (e: Exception) {}
            accrualService.deleteAccrualByBooking(bookingId)
        }

        booking.status = "CANCELLED"
        booking.cancelledBy = cancellingUser
        booking.cancellationReason = reason
        booking.cancellationDate = LocalDateTime.now()
        
        val saved = bookingRepository.save(booking)

        val dateFormatter = DateTimeFormatter.ofPattern("dd/MM/yyyy")
        val timeFormatter = DateTimeFormatter.ofPattern("HH:mm")
        val dateStr = booking.startTime.format(dateFormatter)
        val timeStr = booking.startTime.format(timeFormatter)

        val memberMsg = if (cancellingUser != null && cancellingUser.id == booking.member.id) {
            "$dateStr Tarih ve saat $timeStr için randevu talep ettiğiniz dersiniz iptal edilmiştir."
        } else {
            "$dateStr Tarih ve saat $timeStr için randevu talep ettiğiniz dersiniz, eğitmeniniz ve salon yöneticisi onayı ile iptal edilmiştir. Lütfen yeni bir ders randevusu alınız."
        }
        notificationRepository.save(Notification(user = booking.member, message = memberMsg))

        if (cancellingUser == null || cancellingUser.id != booking.trainer.id) {
            val trainerMsg = "${booking.member.fullName} üyesinin $dateStr $timeStr tarihindeki dersi yönetici tarafından kesin iptal edildi."
            notificationRepository.save(Notification(user = booking.trainer, message = trainerMsg))
        }

        return saved
    }

    @Transactional
    fun trainerRejectBooking(bookingId: Long, trainerId: Long, reason: String? = null, isDirectCancel: Boolean = false): Booking {
        val booking = bookingRepository.findById(bookingId).orElseThrow { Exception("Randevu bulunamadı!") }
        
        if (isDirectCancel) {
            booking.status = "CANCELLED"
            booking.cancellationReason = reason ?: "Eğitmen tarafından 'Katılmadı/Mazeretli' olarak iptal edildi."
            booking.cancellationDate = LocalDateTime.now()
            notificationRepository.save(Notification(
                user = booking.member,
                message = "Randevunuz eğitmen tarafından incelendi ve iptal edildi: $reason"
            ))
        } else {
            booking.status = "PENDING_ADMIN_APPROVAL"
            booking.cancellationReason = reason ?: "Eğitmen tarafından reddedildi, yönetici onayı bekleniyor."

            val formatter = DateTimeFormatter.ofPattern("dd/MM HH:mm")
            val message = "Eğitmen ${booking.trainer.fullName}, ${booking.member.fullName} üyesinin ${booking.startTime.format(formatter)} randevusunu reddetti. Yönetici onayı bekleniyor."

            val admins = userRepository.findAllByGymIdAndRoleAndIsDeletedFalse(booking.gym.id!!, UserRole.ADMIN)
            admins.forEach { admin ->
                notificationRepository.save(Notification(user = admin, message = message))
            }

            notificationRepository.save(Notification(
                user = booking.member,
                message = "Randevunuz eğitmen tarafından incelendi ve yönetici onayına sevk edildi."
            ))
        }

        return bookingRepository.save(booking)
    }

    fun getAdminPendingBookings(gymId: Long): List<Booking> {
        return bookingRepository.findAllByGymIdAndStatusOrderByStartTimeAsc(gymId, "PENDING_ADMIN_APPROVAL")
    }

    @Transactional
    fun confirmAttendance(bookingId: Long, willAttend: Boolean): Booking {
        val booking = bookingRepository.findById(bookingId).orElseThrow { Exception("Randevu bulunamadı!") }
        val formatter = DateTimeFormatter.ofPattern("dd/MM HH:mm")
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
    fun getGymWeeklySchedule(gymId: Long, start: LocalDateTime, end: LocalDateTime): List<Booking> = bookingRepository.findAllActiveByGymIdAndStartTimeBetween(gymId, start, end)

    fun getAvailableSlots(trainerId: Long, gymId: Long, date: LocalDate): List<SlotAvailability> {
        val targetGym = gymRepository.findById(gymId).orElseThrow { Exception("Salon bulunamadı") }
        val slots = mutableListOf<SlotAvailability>()
        val workingDays = (targetGym.workingDays ?: "1,2,3,4,5,6").split(",").mapNotNull { it.toIntOrNull() }

        val dayOfWeekValue = date.dayOfWeek.value
        if (!workingDays.contains(dayOfWeekValue)) {
            return slots
        }

        val openHour = (targetGym.openTime ?: "07:00").split(":").first().toIntOrNull() ?: 7
        val closeHour = (targetGym.closeTime ?: "22:00").split(":").first().toIntOrNull() ?: 22

        for (hour in openHour until closeHour) {
            val startTime = date.atTime(hour, 0)
            val trainer = userRepository.findById(trainerId).get()
            val isOnLeave = trainer.leaveStart != null && trainer.leaveEnd != null &&
                           !startTime.isBefore(trainer.leaveStart) && !startTime.isAfter(trainer.leaveEnd)

            val gymParticipants = bookingRepository.countActiveBookings(gymId, startTime)
            val isTrainerBusy = bookingRepository.findAllActiveByTrainerIdAndStartTimeBetween(trainerId, startTime, startTime.plusMinutes(59)).isNotEmpty()

            val isAvailable = gymParticipants < 4 && !isTrainerBusy && !isOnLeave
            val reason = when {
                isOnLeave -> "Eğitmen İzinli"
                isTrainerBusy -> "Eğitmen Meşgul"
                gymParticipants >= 4 -> "Salon Dolu"
                else -> null
            }
            slots.add(SlotAvailability(startTime, isAvailable, reason, gymParticipants))
        }
        return slots
    }

    @Transactional
    fun createBulkBookings(memberId: Long, trainerId: Long, gymId: Long, startTimes: List<LocalDateTime>, ignoreRules: Boolean = false): List<Booking> {
        val bookings = startTimes.map { createBooking(memberId, trainerId, gymId, it, ignoreRules) }
        if (ignoreRules && bookings.isNotEmpty()) {
            bookings.forEach {
                it.status = "ACTIVE"
                bookingRepository.save(it)
            }
            val member = bookings.first().member
            val trainer = bookings.first().trainer
            val count = bookings.size
            notificationRepository.save(Notification(
                user = trainer,
                message = "Yönetici tarafından ${member.fullName} üyesi ile adınıza $count adet sabit ders programı planlanmıştır."
            ))
            notificationRepository.save(Notification(
                user = member,
                message = "Yönetici tarafından eğitmeniniz ${trainer.fullName} ile $count adet sabit ders programınız oluşturulmuştur."
            ))
        }
        return bookings
    }

    fun getAvailableTrainersForSlot(gymId: Long, startTime: LocalDateTime): List<User> {
        val allTrainers = userRepository.findAllByGymIdAndRoleAndIsDeletedFalse(gymId, UserRole.TRAINER)
        return allTrainers.filter { trainer ->
            val isOnLeave = trainer.leaveStart != null && trainer.leaveEnd != null &&
                           !startTime.isBefore(trainer.leaveStart) && !startTime.isAfter(trainer.leaveEnd)
            val isBusy = bookingRepository.findAllActiveByTrainerIdAndStartTimeBetween(trainer.id!!, startTime, startTime.plusMinutes(59)).isNotEmpty()
            !isOnLeave && !isBusy
        }
    }
}
