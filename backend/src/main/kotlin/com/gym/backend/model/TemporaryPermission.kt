package com.gym.backend.model

import jakarta.persistence.*
import java.time.LocalDateTime

enum class PermissionType {
    MANAGE_USERS,
    MANAGE_SCHEDULE,
    VIEW_REPORTS,
    FULL_ADMIN_ACCESS
}

@Entity
@Table(name = "temporary_permissions")
class TemporaryPermission(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "trainer_id", nullable = false)
    val trainer: User,

    @Enumerated(EnumType.STRING)
    val permission: PermissionType,

    val startTime: LocalDateTime,
    val endTime: LocalDateTime,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "gym_id", nullable = false)
    val gym: Gym,

    val createdAt: LocalDateTime = LocalDateTime.now()
)
