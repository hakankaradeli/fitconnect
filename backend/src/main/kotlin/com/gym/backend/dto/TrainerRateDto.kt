package com.gym.backend.dto

data class TrainerRateUpdateDto(
    val lessonType: String,
    val amount: Double,
    val gymId: Long
)
