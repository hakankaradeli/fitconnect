package com.gym.backend.dto

import java.time.LocalDateTime

data class BookingRequest(
    val memberId: Long,
    val trainerId: Long,
    val gymId: Long,
    val startTime: LocalDateTime
)

data class BulkBookingRequest(
    val memberId: Long,
    val trainerId: Long,
    val gymId: Long,
    val startTimes: List<LocalDateTime>
)
