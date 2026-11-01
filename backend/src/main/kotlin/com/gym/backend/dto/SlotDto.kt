package com.gym.backend.dto

import java.time.LocalDateTime

data class SlotAvailability(
    val startTime: LocalDateTime,
    val isAvailable: Boolean,
    val reason: String? = null,
    val currentParticipants: Int = 0
)
