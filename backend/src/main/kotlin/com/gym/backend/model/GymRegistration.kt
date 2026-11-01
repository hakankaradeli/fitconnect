package com.gym.backend.model

import com.fasterxml.jackson.annotation.JsonIgnoreProperties
import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "gym_registrations")
@JsonIgnoreProperties("hibernateLazyInitializer", "handler")
class GymRegistration(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "gym_id", nullable = false)
    var gym: Gym,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    var user: User,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    var role: UserRole, // MEMBER, TRAINER, ADMIN

    @Column(name = "registered_at", nullable = false)
    var registeredAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "is_active", nullable = false)
    var isActive: Boolean = true,

    @Column(name = "left_at", nullable = true)
    var leftAt: LocalDateTime? = null,

    @Column(columnDefinition = "TEXT", nullable = true)
    var notes: String? = null
) {
    val gymId: Long? get() = gym.id
    val userId: Long? get() = user.id
    val userFullName: String get() = user.fullName
    val userEmail: String get() = user.email
    val gymName: String get() = gym.name
}
