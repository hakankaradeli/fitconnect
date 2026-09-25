package com.gym.backend.model

import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "workouts")
class Workout(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @Column(nullable = false)
    val title: String,

    val description: String? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "member_id", nullable = false)
    val member: User,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "trainer_id", nullable = false)
    val trainer: User,

    @OneToMany(mappedBy = "workout", cascade = [CascadeType.ALL], orphanRemoval = true)
    var exercises: MutableList<WorkoutExercise> = mutableListOf(),

    val createdAt: LocalDateTime = LocalDateTime.now()
)
