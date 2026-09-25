package com.gym.backend.util

import com.gym.backend.model.Gym
import com.gym.backend.model.User
import com.gym.backend.model.UserRole
import com.gym.backend.repository.GymRepository
import com.gym.backend.repository.UserRepository
import org.springframework.boot.CommandLineRunner
import org.springframework.stereotype.Component

@Component
class DataInitializer(
    private val userRepository: UserRepository,
    private val gymRepository: GymRepository,
    private val userService: com.gym.backend.service.UserService
) : CommandLineRunner {

    override fun run(vararg args: String?) {
        try {
            // 0. Eksik verileri onar (isDeleted, isActive null olanları düzelt)
            userService.repairMissingData()
        } catch (e: Exception) {
            println("--- VERI ONARIMI HATASI: ${e.message} ---")
        }

        // 1. Önce bir Salon (Gym) oluşturalım...
        val gymName = "HK Fit Connect Studio"
        val gym = gymRepository.findByName(gymName) ?: gymRepository.save(
            Gym(
                name = gymName,
                primaryColor = "#8E44AD",
                logoUrl = "https://api.studionuz.com/logo.png"
            )
        )

        // 2. Admin kullanıcısını oluşturalım
        try {
            val adminEmail = "admin@hkfitconnect.com"
            if (userRepository.findByEmail(adminEmail) == null) {
                val adminUser = User(
                    email = adminEmail,
                    passwordHash = "123456", // Not: Gerçekte encode edilmeli
                    fullName = "HK Admin",
                    role = UserRole.ADMIN,
                    gym = gym
                )
                userRepository.save(adminUser)
                println("--- TEST VERİSİ: Admin hesabı oluşturuldu ($adminEmail / 123456) ---")
            }
        } catch (e: Exception) {
            println("--- ADMIN OLUSTURMA HATASI: Karakter kodlamasindan kaynakli olabilir. ---")
        }
    }
}
