package com.gym.backend.model

import jakarta.persistence.*

@Entity
@Table(name = "trainer_rates")
class TrainerRate(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "trainer_id", nullable = false)
    val trainer: User,

    val lessonType: String, // PT Bireysel, PT Duo vb.
    
    var amount: Double,

    val gymId: Long
)
