package com.gym.backend.dto

data class PerformedExerciseRequest(
    val exerciseName: String,
    val muscleGroup: String? = null,
    val sets: Int? = null,
    val reps: Int? = null,
    val weight: String? = null,
    val notes: String? = null
)
