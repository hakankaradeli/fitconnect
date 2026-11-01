package com.gym.backend.model

import jakarta.persistence.*
import java.time.LocalDateTime

enum class AppRegistrationEntityType {
    USER,
    GYM
}

@Entity
@Table(name = "app_registrations")
class AppRegistration(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "entity_type", nullable = false)
    var entityType: AppRegistrationEntityType,

    @Column(name = "user_id", nullable = true)
    var userId: Long? = null,

    @Column(name = "gym_id", nullable = true)
    var gymId: Long? = null,

    @Column(nullable = false)
    var email: String,

    @Column(name = "full_name_or_title", nullable = false)
    var fullNameOrTitle: String,

    @Column(nullable = true)
    var role: String? = null, // MEMBER, TRAINER, ADMIN, SUPER_ADMIN, GYM

    @Column(name = "registered_at", nullable = false)
    var registeredAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "ip_address", nullable = true)
    var ipAddress: String? = null,

    @Column(name = "device_info", nullable = true)
    var deviceInfo: String? = null,

    @Column(columnDefinition = "TEXT", nullable = true)
    var notes: String? = null
)
