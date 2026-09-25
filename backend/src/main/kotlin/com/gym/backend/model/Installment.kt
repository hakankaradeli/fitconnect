package com.gym.backend.model

import jakarta.persistence.*
import java.time.LocalDate

enum class PaymentStatus { PENDING, PAID, OVERDUE }

@Entity
@Table(name = "installments")
class Installment(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "member_id", nullable = false)
    val member: User,

    val amount: Double,
    val dueDate: LocalDate,
    val creditsToLoad: Int, // Bu taksit ödendiğinde yüklenecek kredi miktarı

    @Enumerated(EnumType.STRING)
    var status: PaymentStatus = PaymentStatus.PENDING,

    val gymId: Long // Multi-tenant izolasyonu
)
