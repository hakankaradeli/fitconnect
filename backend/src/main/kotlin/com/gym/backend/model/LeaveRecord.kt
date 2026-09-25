package com.gym.backend.model

import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "leave_records")
class LeaveRecord(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "trainer_id", nullable = false)
    val trainer: User,

    val startDate: LocalDateTime,
    val endDate: LocalDateTime,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "replacement_trainer_id")
    val replacementTrainer: User? = null,

    var status: String = "ACTIVE", // ACTIVE, CANCELLED
    
    val createdAt: LocalDateTime = LocalDateTime.now()
)
