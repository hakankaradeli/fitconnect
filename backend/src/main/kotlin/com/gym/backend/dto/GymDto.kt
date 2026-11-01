package com.gym.backend.dto

data class GymCreateRequest(
    val gymName: String,
    val primaryColor: String? = "#3F51B5",
    val logoUrl: String? = null,
    val address: String? = null,
    val adminEmail: String,
    val adminFullName: String,
    val adminPassword: String,
    val adminPhone: String? = null
)

data class GymSummaryResponse(
    val gymId: Long,
    val gymName: String,
    val primaryColor: String?,
    val logoUrl: String?,
    val address: String?,
    val isActive: Boolean,
    val memberCount: Long,
    val trainerCount: Long,
    val adminEmail: String?,
    val adminFullName: String?,
    val adminPhone: String?
)
