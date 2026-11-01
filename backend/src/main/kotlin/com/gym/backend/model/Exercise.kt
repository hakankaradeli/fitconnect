package com.gym.backend.model

import jakarta.persistence.*

@Entity
@Table(name = "exercises")
class Exercise(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @Column(nullable = false)
    val name: String,

    val category: String, // Chest, Back, Legs, etc.

    @Column(length = 1000)
    val description: String? = null,

    val videoUrl: String? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "gym_id", nullable = false)
    val gym: Gym // Multi-tenant: Egzersiz bir salona ait olabilir veya genel olabilir (bu yapı için nullable olabilir ama şimdilik zorunlu tutuyoruz)
)
