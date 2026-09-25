package com.gym.backend.service

import com.gym.backend.model.MemberCredit
import com.gym.backend.model.PaymentStatus
import com.gym.backend.model.Notification
import com.gym.backend.model.Installment
import com.gym.backend.repository.InstallmentRepository
import com.gym.backend.repository.MemberCreditRepository
import com.gym.backend.repository.UserRepository
import com.gym.backend.repository.NotificationRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDate

@Service
class FinanceService(
    private val installmentRepository: InstallmentRepository,
    private val creditRepository: MemberCreditRepository,
    private val userRepository: UserRepository,
    private val notificationRepository: NotificationRepository,
    private val whatsAppService: WhatsAppService
) {
    fun getMemberBalance(memberId: Long): MemberCredit {
        return creditRepository.findByMemberId(memberId)
            ?: throw Exception("Kredi hesabı bulunamadı")
    }

    @Transactional
    fun deductCreditForSession(memberId: Long) {
        val credit = creditRepository.findByMemberId(memberId) 
            ?: throw Exception("Kredi hesabı bulunamadı")
        credit.totalUsed += 1
        val saved = creditRepository.save(credit)

        // Paket bitimine 3 ders kala yenileme CTA uyarısı (Push + WhatsApp)
        if (saved.netBalance in 0..3) {
            val member = credit.member
            val message = "Paket Yenileme Hatırlatması: Hesabınızda son ${saved.netBalance} ders krediniz kaldı! Antrenmanlarınıza kesintisiz devam etmek için salon yöneticinizle iletişime geçip yeni paket alabilirsiniz."
            
            notificationRepository.save(Notification(user = member, message = message))
            whatsAppService.sendMessage(member.phone, message)
        }
    }

    @Transactional
    fun processPayment(installmentId: Long) {
        val installment = installmentRepository.findById(installmentId).orElseThrow { Exception("Taksit bulunamadı") }
        if (installment.status == PaymentStatus.PAID) return

        val credit = creditRepository.findByMemberId(installment.member.id!!)
            ?: throw Exception("Üye kredi hesabı bulunamadı")
        
        credit.totalPurchased += installment.creditsToLoad
        installment.status = PaymentStatus.PAID
        
        creditRepository.save(credit)
        installmentRepository.save(installment)
    }

    @Transactional
    fun addManualCredit(memberId: Long, amount: Int, paymentAmount: Double, isPaid: Boolean, dueDate: LocalDate?) {
        val member = userRepository.findById(memberId).orElseThrow { Exception("Üye bulunamadı") }
        val credit = creditRepository.findByMemberId(memberId)
            ?: throw Exception("Kredi hesabı bulunamadı")
        
        // 1. Krediyi hemen ekle
        credit.totalPurchased += amount
        creditRepository.save(credit)

        // 2. Ödeme kaydı oluştur
        val installment = Installment(
            member = member,
            amount = paymentAmount,
            dueDate = dueDate ?: LocalDate.now(),
            creditsToLoad = amount,
            status = if (isPaid) PaymentStatus.PAID else PaymentStatus.PENDING,
            gymId = member.gym.id!!
        )
        installmentRepository.save(installment)

        // 3. Bildirim ekle (Hemen veya İleri tarihli hatırlatma için)
        if (!isPaid && dueDate != null) {
            notificationRepository.save(Notification(
                user = member,
                message = "Ödeme Hatırlatması: $amount kredi için $paymentAmount TL tutarındaki ödemeniz $dueDate tarihindedir."
            ))
        } else if (isPaid) {
            notificationRepository.save(Notification(
                user = member,
                message = "$amount adet yeni ders kredisi hesabınıza yüklendi. Teşekkürler!"
            ))
        }
    }

    fun getAllInstallmentsByGym(gymId: Long): List<Installment> {
        return installmentRepository.findAllByGymIdOrderByDueDateDesc(gymId)
    }
}
