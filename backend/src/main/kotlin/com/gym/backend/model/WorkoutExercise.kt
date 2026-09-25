package com.gym.backend.model

import jakarta.persistence.*

@Entity
@Table(name = "workout_exercises")
class WorkoutExercise(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "workout_id", nullable = false)
    val workout: Workout,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "exercise_id", nullable = false)
    val exercise: Exercise,

    val sets: Int,
    val reps: Int,
    val restSeconds: Int? = 60,
    
    val orderIndex: Int = 0 // Sıralama için
)
