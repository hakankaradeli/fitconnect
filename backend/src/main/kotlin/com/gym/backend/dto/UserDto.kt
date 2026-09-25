package com.gym.backend.dto

import com.gym.backend.model.UserRole

data class UserCreateRequest(
    val email: String,
    val fullName: String,
    val password: String,
    val phone: String,
    val role: UserRole,
    val gymId: Long,
    
    // Üye için isteğe bağlı alanlar
    val trainerId: Long? = null,
    val lessonType: String? = null,
    
    // Eğitmen için isteğe bağlı alanlar
    val canTeach: List<String>? = null
)

data class UpdateProfileRequest(
    val firstName: String? = null,
    val lastName: String? = null,
    val phone: String? = null,
    @org.springframework.format.annotation.DateTimeFormat(iso = org.springframework.format.annotation.DateTimeFormat.ISO.DATE)
    val birthDate: java.time.LocalDate? = null,
    val gender: String? = null,
    val profileImageUrl: String? = null,
    val instagram: String? = null,
    val linkedin: String? = null,
    val twitter: String? = null,
    val currentPassword: String? = null,
    val newPassword: String? = null
)
