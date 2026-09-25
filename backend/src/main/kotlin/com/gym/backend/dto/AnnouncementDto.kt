package com.gym.backend.dto

data class AnnouncementCreateRequest(
    val gymId: Long,
    val title: String,
    val content: String,
    val imageUrl: String? = null,
    val targetRole: String? = "ALL"
)
