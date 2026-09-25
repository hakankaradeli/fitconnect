package com.gym.backend.dto

// Giriş isteği
data class LoginRequest(
    val email: String,
    val password: String
)

// Giriş başarılı olduğunda dönecek cevap
data class LoginResponse(
    val token: String,
    val userId: Long,
    val fullName: String,
    val email: String? = null,
    val phone: String? = null,
    val firstName: String? = null,
    val lastName: String? = null,
    val birthDate: String? = null,
    val gender: String? = null,
    val role: String,
    val gymId: Long,
    val gymName: String,
    val primaryColor: String,
    val logoUrl: String?,
    val assignedTrainer: Map<String, Any>? = null,
    val tempPermissions: List<String> = emptyList(),
    val profileImageUrl: String? = null,
    val instagram: String? = null,
    val linkedin: String? = null,
    val twitter: String? = null
)
