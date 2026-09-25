package com.gym.backend.service

import com.gym.backend.dto.LoginRequest
import com.gym.backend.dto.LoginResponse
import com.gym.backend.repository.UserRepository
import org.springframework.stereotype.Service

@Service
class AuthService(
    private val userRepository: UserRepository,
    private val jwtService: JwtService,
    private val delegationService: DelegationService
    // Not: Gerçek projede BCryptPasswordEncoder kullanılmalı
) {
    fun authenticate(request: LoginRequest): LoginResponse {
        println("Giriş denemesi: ${request.email}")
        val user = userRepository.findByEmail(request.email)
            ?: throw Exception("Kullanıcı bulunamadı!")

        // Şifre kontrolü (Şimdilik düz metin, ilerde şifrelenecek)
        if (user.passwordHash != request.password) {
            throw Exception("Hatalı şifre!")
        }

        if (user.isActive == false) {
            throw Exception("Hesabınız pasif durumdadır. Lütfen yönetici ile iletişime geçin.")
        }

        val token = jwtService.generateToken(user.email, user.role.name)

        val assignedTrainerData = user.assignedTrainer?.let {
            mapOf(
                "id" to it.id!!,
                "fullName" to it.fullName
            )
        }

        val tempPermissions = delegationService.getActivePermissions(user.email).map { it.name }

        // PRD gereği Multi-tenant bilgilerini de dönüyoruz
        return LoginResponse(
            token = token,
            userId = user.id!!,
            fullName = user.fullName,
            email = user.email,
            phone = user.phone,
            firstName = user.firstName,
            lastName = user.lastName,
            birthDate = user.birthDate?.toString(),
            gender = user.gender,
            role = user.role.name,
            gymId = user.gym.id!!,
            gymName = user.gym.name,
            primaryColor = user.gym.primaryColor ?: "#3F51B5",
            logoUrl = user.gym.logoUrl,
            assignedTrainer = assignedTrainerData,
            tempPermissions = tempPermissions,
            profileImageUrl = user.profileImageUrl,
            instagram = user.instagram,
            linkedin = user.linkedin,
            twitter = user.twitter
        )
    }
}
