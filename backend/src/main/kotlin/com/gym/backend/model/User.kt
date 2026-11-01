package com.gym.backend.model

import jakarta.persistence.*

enum class UserRole { SUPER_ADMIN, ADMIN, TRAINER, MEMBER }

@Entity
@Table(name = "users")
class User(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @Column(unique = true, nullable = false)
    var email: String,

    @com.fasterxml.jackson.annotation.JsonIgnore
    @Column(nullable = false)
    var passwordHash: String,

    var fullName: String,

    var phone: String? = null,

    @Enumerated(EnumType.STRING)
    var role: UserRole, // ADMIN, TRAINER, MEMBER

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "gym_id", nullable = true)
    var gym: Gym? = null, // Multi-Tenant bağlantısı (İsteğe bağlı - QR ile salon kaydı yapılabilir)

    // Üye için atanan eğitmen ve ders tipi
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assigned_trainer_id")
    var assignedTrainer: User? = null,

    var assignedLessonType: String? = null, // PT_1TO1, PT_DUO, REFORMER_GROUP

    // Eğitmen için verebildiği ders türleri
    @ElementCollection
    @CollectionTable(name = "user_teach_types", joinColumns = [JoinColumn(name = "user_id")])
    @Column(name = "lesson_type")
    var canTeach: List<String> = mutableListOf(),

    @Column(name = "is_active", nullable = true)
    var isActive: Boolean? = true,

    @Column(name = "is_deleted", nullable = true)
    var isDeleted: Boolean? = false,
    
    var leaveStart: java.time.LocalDateTime? = null,
    var leaveEnd: java.time.LocalDateTime? = null,

    @Column(columnDefinition = "TEXT")
    var profileImageUrl: String? = null,
    var instagram: String? = null,
    var linkedin: String? = null,
    var twitter: String? = null,

    var firstName: String? = null,
    var lastName: String? = null,
    var birthDate: java.time.LocalDate? = null,
    var gender: String? = null,

    var freezeStart: java.time.LocalDate? = null,
    var freezeEnd: java.time.LocalDate? = null,
    var freezeReason: String? = null,

    @Column(name = "created_at", nullable = true)
    var createdAt: java.time.LocalDateTime? = java.time.LocalDateTime.now(),

    @Transient
    var appRegistrationDate: java.time.LocalDateTime? = null,

    @Transient
    var gymRegistrationDate: java.time.LocalDateTime? = null
)
