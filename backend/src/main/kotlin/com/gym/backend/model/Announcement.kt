package com.gym.backend.model

import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "announcements")
class Announcement(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "gym_id", nullable = false)
    val gym: Gym,

    val title: String,

    @Column(columnDefinition = "TEXT", nullable = false)
    val content: String,

    val imageUrl: String? = null,

    val targetRole: String? = "ALL", // ALL, MEMBER, TRAINER

    val createdAt: LocalDateTime = LocalDateTime.now()
)
