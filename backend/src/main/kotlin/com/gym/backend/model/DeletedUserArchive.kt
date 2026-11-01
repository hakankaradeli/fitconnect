package com.gym.backend.model

import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "deleted_user_archives")
class DeletedUserArchive(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    val originalUserId: Long,
    val fullName: String,
    val email: String,
    val phone: String? = null,
    val role: String,
    val gymName: String? = null,

    val registerIpAddress: String? = null,
    val registerDeviceInfo: String? = null,
    val registeredAt: LocalDateTime? = null,

    val deleteIpAddress: String? = null,
    val deleteDeviceInfo: String? = null,
    val deletedAt: LocalDateTime = LocalDateTime.now(),

    // 200 gün sonra otomatik temizlik tarihi
    val retentionPurgeDate: LocalDateTime = LocalDateTime.now().plusDays(200)
)
