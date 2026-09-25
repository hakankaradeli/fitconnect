package com.gym.backend.model

import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "notifications")
class Notification(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    val user: User, // Bildirimi alacak kişi (Eğitmen)

    val message: String,
    
    val createdAt: LocalDateTime = LocalDateTime.now(),
    
    var isRead: Boolean = false
)
