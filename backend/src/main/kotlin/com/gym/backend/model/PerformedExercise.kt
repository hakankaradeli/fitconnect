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
    val sets: Int? = null,
    val reps: Int? = null,
    val weight: String? = null, // e.g., "29 KG"
    val notes: String? = null
)
