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
import java.time.format.DateTimeFormatter

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
        if (credit.netBalance <= 0) {
            throw Exception("Krediniz yetersiz. Lütfen yeni bir paket satın alınız.")
        }
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
    fun refundCreditForSession(memberId: Long) {
        val credit = creditRepository.findByMemberId(memberId)
            ?: throw Exception("Kredi hesabı bulunamadı")
        if (credit.totalUsed > 0) {
            credit.totalUsed -= 1
        } else {
            credit.totalPurchased += 1
        }
        creditRepository.save(credit)
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
        val upfront = if (isPaid) paymentAmount else 0.0
        addPartialCredit(memberId, amount, paymentAmount, upfront, dueDate)
    }

    @Transactional
    fun addPartialCredit(memberId: Long, amount: Int, totalAmount: Double, upfrontAmount: Double, dueDate: LocalDate?) {
        val member = userRepository.findById(memberId).orElseThrow { Exception("Üye bulunamadı") }
        val credit = creditRepository.findByMemberId(memberId)
            ?: throw Exception("Kredi hesabı bulunamadı")
        val gymId = member.gym?.id ?: 1L

        credit.totalPurchased += amount
        creditRepository.save(credit)

        val remainingAmount = (totalAmount - upfrontAmount).coerceAtLeast(0.0)
        if (upfrontAmount > 0.0) {
            val paidInstallment = Installment(
                member = member,
                amount = upfrontAmount,
                dueDate = LocalDate.now(),
                creditsToLoad = amount,
                status = PaymentStatus.PAID,
                gymId = gymId
            )
            installmentRepository.save(paidInstallment)
        }

        if (remainingAmount > 0.0 && dueDate != null) {
            val pendingInstallment = Installment(
                member = member,
                amount = remainingAmount,
                dueDate = dueDate,
                creditsToLoad = 0,
                status = PaymentStatus.PENDING,
                gymId = gymId
            )
            installmentRepository.save(pendingInstallment)
            val formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy")
            val dateStr = dueDate.format(formatter)
            val msg = "Kısmi Ödeme Kaydı: Toplam ${totalAmount.toInt()} TL tutarındaki paket ödemenizin ${upfrontAmount.toInt()} TL'si peşin alındı. Kalan ${remainingAmount.toInt()} TL son ödeme tarihi: $dateStr"
            notificationRepository.save(Notification(user = member, message = msg))
            whatsAppService.sendMessage(member.phone, msg)
        } else if (remainingAmount <= 0.0) {
            val msg = "$amount adet yeni ders kredisi (Toplam ${totalAmount.toInt()} TL) hesabınıza başarıyla yüklendi. Teşekkürler!"
            notificationRepository.save(Notification(user = member, message = msg))
        }
    }

    fun getAllInstallmentsByGym(gymId: Long): List<Installment> {
        return installmentRepository.findAllByGymIdOrderByDueDateDesc(gymId)
    }

    @Transactional
    fun updateMemberCredit(memberId: Long, newTotalPurchased: Int, newTotalUsed: Int): MemberCredit {
        val credit = creditRepository.findByMemberId(memberId)
            ?: throw Exception("Kredi hesabı bulunamadı")
        if (newTotalUsed > newTotalPurchased) {
            throw Exception("Kullanılan kredi, toplam alınan krediden fazla olamaz.")
        }
        credit.totalPurchased = newTotalPurchased
        credit.totalUsed = newTotalUsed
        val saved = creditRepository.save(credit)
        val msg = "Yönetici tarafından kredi bilgileriniz güncellendi. Yeni Kalan Krediniz: ${saved.netBalance} (Toplam: $newTotalPurchased, Kullanılan: $newTotalUsed)"
        notificationRepository.save(Notification(user = credit.member, message = msg))
        return saved
    }
}
