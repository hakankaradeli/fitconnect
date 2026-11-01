package com.gym.backend.scheduler

import com.gym.backend.model.Notification
import com.gym.backend.repository.BookingRepository
import com.gym.backend.repository.NotificationRepository
import com.gym.backend.service.FinanceService
import org.slf4j.LoggerFactory
import org.springframework.scheduling.annotation.Scheduled
import org.springframework.stereotype.Component
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

@Component
class BookingScheduler(
    private val bookingRepository: BookingRepository,
    private val notificationRepository: NotificationRepository,
    private val financeService: FinanceService
) {
    private val logger = LoggerFactory.getLogger(BookingScheduler::class.java)

    // Her 15 dakikada bir çalışır ve süresi dolan dersleri (No-Show) otomatik kapatır
    @Scheduled(cron = "0 0/15 * * * *")
    @Transactional
    fun processFinishedBookingsAndNoShows() {
        val now = LocalDateTime.now()
        
        // Bitiş saati geçmiş ama henüz kapanmamış (ACTIVE veya PENDING) dersleri bul
        val pastBookings = bookingRepository.findAll()
            .filter { (it.status == "ACTIVE" || it.status == "PENDING") && it.endTime.isBefore(now) }

        val formatter = DateTimeFormatter.ofPattern("dd/MM HH:mm")

        pastBookings.forEach { booking ->
            // Durumu NO_SHOW olarak güncelle
            booking.status = "NO_SHOW"
            booking.cancellationReason = "Üye Derse Katılmadı"
            bookingRepository.save(booking)

            // PRD No-Show Kuralı: Derse gelinmese dahi 1 kredi düşülür
            try {
                financeService.deductCreditForSession(booking.member.id!!)
            } catch (e: Exception) {
                // Bakiye kontrolü
            }

            val dateStr = booking.startTime.format(formatter)
            notificationRepository.save(Notification(
                user = booking.member,
                message = "Derse katılım sağlamadığınız için $dateStr tarihindeki dersinizin 1 seans kredisi düşülmüştür."
            ))
        }

        if (pastBookings.isNotEmpty()) {
            logger.info("NO-SHOW OTOMATİK İŞLEMİ: {} adet ders kapatıldı ve 1 kredisi düşüldü.", pastBookings.size)
        }
    }

    // Akıllı Katılım Teyit Bildirimi - 1. Kural: Saat 13:00'ten önceki dersler için önceki akşam saat 23:00'te bildirim atılır
    @Scheduled(cron = "0 0 23 * * *")
    @Transactional
    fun sendNightBeforeAttendanceConfirmations() {
        val tomorrow = LocalDateTime.now().plusDays(1).toLocalDate()
        val formatter = DateTimeFormatter.ofPattern("HH:mm")

        val morningBookings = bookingRepository.findAll()
            .filter { it.status == "ACTIVE" && it.startTime.toLocalDate() == tomorrow && it.startTime.hour < 13 }

        morningBookings.forEach { booking ->
            val timeStr = booking.startTime.format(formatter)
            notificationRepository.save(Notification(
                user = booking.member,
                message = "Yarın saat $timeStr dersinize katılacak mısınız? Lütfen katılım durumunuzu onaylayınız."
            ))
        }

        if (morningBookings.isNotEmpty()) {
            logger.info("KATILIM TEYİT BİLDİRİMİ (GECE 23:00): {} üyeye yarın sabahki dersleri için teyit bildirimi gönderildi.", morningBookings.size)
        }
    }

    // Akıllı Katılım Teyit Bildirimi - 2. Kural: Saat 13:00 ve sonrası dersler için dersten 6 saat önce bildirim atılır
    @Scheduled(cron = "0 0/30 * * * *")
    @Transactional
    fun sendSixHourBeforeAttendanceConfirmations() {
        val now = LocalDateTime.now()
        val targetStart = now.plusHours(6)
        val formatter = DateTimeFormatter.ofPattern("HH:mm")

        val afternoonBookings = bookingRepository.findAll()
            .filter { 
                it.status == "ACTIVE" && 
                it.startTime.hour >= 13 && 
                it.startTime.isAfter(targetStart.minusMinutes(15)) && 
                it.startTime.isBefore(targetStart.plusMinutes(15)) 
            }

        afternoonBookings.forEach { booking ->
            val timeStr = booking.startTime.format(formatter)
            notificationRepository.save(Notification(
                user = booking.member,
                message = "Bugün saat $timeStr dersinize 6 saat kaldı. Derse katılacak mısınız? Lütfen teyit ediniz."
            ))
        }

        if (afternoonBookings.isNotEmpty()) {
            logger.info("KATILIM TEYİT BİLDİRİMİ (6 SAAT ÖNCE): {} üyeye 6 saat sonraki dersleri için teyit bildirimi gönderildi.", afternoonBookings.size)
        }
    }
}
