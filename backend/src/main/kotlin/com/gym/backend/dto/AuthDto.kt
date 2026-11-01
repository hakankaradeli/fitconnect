package com.gym.backend.dto

import com.gym.backend.model.UserRole

// Giriş isteği
data class LoginRequest(
    val email: String,
    val password: String
)

// Refresh Token İsteği
data class RefreshTokenRequest(
    val refreshToken: String
)

// Refresh Token Cevabı
data class RefreshTokenResponse(
    val token: String,
    val refreshToken: String
)

// Kayıt İsteği (Üye ve Eğitmenler İçin)
data class RegisterRequest(
    val fullName: String,
    val email: String,
    val phone: String? = null,
    val password: String,
    val role: UserRole? = UserRole.MEMBER,
    val gymId: Long? = null,
    val termsAccepted: Boolean? = true,
    val healthDataConsentAccepted: Boolean? = true,
    val marketingConsentAccepted: Boolean? = false,
    val ipAddress: String? = null,
    val deviceInfo: String? = null
)

// Genel Spor Salonu Listesi (Kayıt Ekranı Dropdown İçin)
data class PublicGymResponse(
    val gymId: Long,
    val gymName: String,
    val logoUrl: String?,
    val primaryColor: String?
)

// Giriş başarılı olduğunda dönecek cevap
data class LoginResponse(
    val token: String,
    val refreshToken: String? = null,
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
    val secondaryColor: String? = "#00BFA5",
    val isGradient: Boolean? = false,
    val offeredLessonGroups: String? = null,
    val openTime: String? = "07:00",
    val closeTime: String? = "22:00",
    val workingDays: String? = "1,2,3,4,5,6",
    val logoUrl: String?,
    val assignedTrainer: Map<String, Any>? = null,
    val tempPermissions: List<String> = emptyList(),
    val profileImageUrl: String? = null,
    val instagram: String? = null,
    val linkedin: String? = null,
    val twitter: String? = null
)
