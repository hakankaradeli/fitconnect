package com.gym.backend.model

import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "surveys")
class Survey(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @OneToOne
    @JoinColumn(name = "booking_id", nullable = false)
    val booking: Booking,

    val rating: Int, // 1-5 yıldız

    @Column(length = 500)
    val comment: String? = null,

    val createdAt: LocalDateTime = LocalDateTime.now(),

    val gymId: Long // Multi-tenant izolasyonu
)
