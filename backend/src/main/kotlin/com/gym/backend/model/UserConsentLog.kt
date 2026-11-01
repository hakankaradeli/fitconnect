package com.gym.backend.model

import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "user_consent_logs")
class UserConsentLog(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = true)
    val user: User? = null,

    val userEmail: String,
    val userFullName: String,

    val termsAccepted: Boolean = true,
    val healthDataConsentAccepted: Boolean = true,
    val marketingConsentAccepted: Boolean = false,

    val ipAddress: String? = null,
    val deviceInfo: String? = null,

    val createdAt: LocalDateTime = LocalDateTime.now()
)
