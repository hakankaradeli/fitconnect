package com.gym.backend.model

import com.fasterxml.jackson.annotation.JsonIgnore
import jakarta.persistence.*

@Entity
@Table(name = "performed_exercises")
class PerformedExercise(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "booking_id", nullable = false)
    @JsonIgnore
    val booking: Booking,

    val exerciseName: String,
    val muscleGroup: String? = null,
    val sets: Int? = null,
    val reps: Int? = null,
    val weight: String? = null,
    val notes: String? = null
)
