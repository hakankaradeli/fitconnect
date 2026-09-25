package com.gym.backend.scheduler

import com.gym.backend.model.Notification
import com.gym.backend.model.PaymentStatus
import com.gym.backend.repository.InstallmentRepository
import com.gym.backend.repository.NotificationRepository
import com.gym.backend.service.WhatsAppService
import org.springframework.scheduling.annotation.Scheduled
import org.springframework.stereotype.Component
import java.time.LocalDate
import java.time.format.DateTimeFormatter

@Component
class FinanceScheduler(
    private val installmentRepository: InstallmentRepository,
    private val notificationRepository: NotificationRepository,
    private val whatsAppService: WhatsAppService
) {

    // Her gün sabah 09:00'da çalışır (T-1 Gün Hatırlatması)
    @Scheduled(cron = "0 0 9 * * *")
    fun checkPendingInstallmentsDueTomorrow() {
        val tomorrow = LocalDate.now().plusDays(1)
        val pendingDueTomorrow = installmentRepository.findAllByDueDateAndStatus(tomorrow, PaymentStatus.PENDING)

        val formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy")

        pendingDueTomorrow.forEach { installment ->
            val dateStr = installment.dueDate.format(formatter)
            val message = "Ödeme Hatırlatması: ${installment.amount.toInt()} TL tutarındaki ödeme vadeniz yarın ($dateStr). Lütfen ödemenizi gerçekleştiriniz."

            // 1. Uygulama İçi Bildirim
            notificationRepository.save(Notification(user = installment.member, message = message))

            // 2. WhatsApp Otomatik Bildirimi
            installment.member.phone?.let { phone ->
                whatsAppService.sendMessage(phone, message)
            }
        }

        if (pendingDueTomorrow.isNotEmpty()) {
            println("--- T-1 FİNANS HATIRLATMA: ${pendingDueTomorrow.size} üyeye yarınki ödemeleri için bildirim gönderildi. ---")
        }
    }
}
