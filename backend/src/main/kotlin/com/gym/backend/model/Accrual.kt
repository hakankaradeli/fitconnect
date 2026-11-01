package com.gym.backend.model

import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "accruals")
class Accrual(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "trainer_id", nullable = false)
    val trainer: User,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "gym_id", nullable = false)
    val gym: Gym,

    @OneToOne
    @JoinColumn(name = "booking_id", nullable = false)
    val booking: Booking,

    val amount: Double, // O dersten kazanılan tutar

    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "is_paid", nullable = true)
    var isPaid: Boolean? = false // Yönetici ödeme yapınca true olacak
)
