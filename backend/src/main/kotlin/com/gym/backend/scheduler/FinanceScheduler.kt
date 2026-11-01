package com.gym.backend.scheduler

import com.gym.backend.model.Notification
import com.gym.backend.model.PaymentStatus
import com.gym.backend.model.UserRole
import com.gym.backend.repository.InstallmentRepository
import com.gym.backend.repository.NotificationRepository
import com.gym.backend.repository.UserRepository
import com.gym.backend.service.WhatsAppService
import org.slf4j.LoggerFactory
import org.springframework.scheduling.annotation.Scheduled
import org.springframework.stereotype.Component
import java.time.LocalDate
import java.time.format.DateTimeFormatter

@Component
class FinanceScheduler(
    private val installmentRepository: InstallmentRepository,
    private val notificationRepository: NotificationRepository,
    private val userRepository: UserRepository,
    private val deletedUserArchiveRepository: com.gym.backend.repository.DeletedUserArchiveRepository,
    private val whatsAppService: WhatsAppService
) {
    private val logger = LoggerFactory.getLogger(FinanceScheduler::class.java)

    // Her gün gece 02:00'de çalışır: 200 gününü doldurmuş silinen arşiv kayıtlarını veritabanından kalıcı temizler
    @Scheduled(cron = "0 0 2 * * *")
    fun purgeExpiredDeletedUserArchives() {
        try {
            val purgedCount = deletedUserArchiveRepository.deleteAllByRetentionPurgeDateBefore(java.time.LocalDateTime.now())
            if (purgedCount > 0) {
                logger.info("200 gün süresi dolan arşiv temizliği: {} silinmiş kullanıcı arşivi veritabanından kalıcı temizlendi.", purgedCount)
            }
        } catch (e: Exception) {
            logger.warn("Arşiv temizleme zamanlayıcı uyarısı: {}", e.message)
        }
    }

    // Her gün sabah 09:00'da çalışır (T-3 Gün Hatırlatması, T-0 Ödeme Günü Bildirimi ve Yöneticisine Rapor)
    @Scheduled(cron = "0 0 9 * * *")
    fun checkPendingInstallmentsAndNotify() {
        val today = LocalDate.now()
        val threeDaysLater = today.plusDays(3)
        val formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy")

        // 1. Güne 3 Kala Bildirimleri (Üyeye T-3)
        val pendingInThreeDays = installmentRepository.findAllByDueDateAndStatus(threeDaysLater, PaymentStatus.PENDING)
        pendingInThreeDays.forEach { installment ->
            val dateStr = installment.dueDate.format(formatter)
            val msg = "Ödeme Hatırlatması: ${installment.amount.toInt()} TL tutarındaki kalan ödeme vadenize 3 gün kaldı ($dateStr). Lütfen ödemenizi tamamlayınız."
            notificationRepository.save(Notification(user = installment.member, message = msg))
            installment.member.phone?.let { phone -> whatsAppService.sendMessage(phone, msg) }
        }

        // 2. Bugün Ödeme Günü Bildirimleri (Üyeye T-0)
        val pendingToday = installmentRepository.findAllByDueDateAndStatus(today, PaymentStatus.PENDING)
        pendingToday.forEach { installment ->
            val msg = "Bugün Son Ödeme Günü! ${installment.amount.toInt()} TL tutarındaki kalan ödemenizin son ödeme günüdür. Lütfen ödemenizi gerçekleştiriniz."
            notificationRepository.save(Notification(user = installment.member, message = msg))
            installment.member.phone?.let { phone -> whatsAppService.sendMessage(phone, msg) }
        }

        // 3. Ödeme Günü Salon Yöneticisine (Admin) Raporlama
        if (pendingToday.isNotEmpty()) {
            val gymGrouped = pendingToday.groupBy { it.gymId }
            gymGrouped.forEach { (gymId, installments) ->
                val admins = userRepository.findAllByGymIdAndRoleAndIsDeletedFalse(gymId, UserRole.ADMIN)
                val memberNames = installments.joinToString(", ") { "${it.member.fullName} (${it.amount.toInt()} TL)" }
                val adminMsg = "Bugün Ödemesi Olan Üyeler Raporu: Bugün ödeme yapacak üyeleriniz: $memberNames"
                
                admins.forEach { admin ->
                    notificationRepository.save(Notification(user = admin, message = adminMsg))
                }
            }
        }

        if (pendingInThreeDays.isNotEmpty() || pendingToday.isNotEmpty()) {
            logger.info("Finans ve rapor hatırlatması: T-3 ({}), T-0 ({}) işlem tamamlandı.", pendingInThreeDays.size, pendingToday.size)
        }
    }
}
