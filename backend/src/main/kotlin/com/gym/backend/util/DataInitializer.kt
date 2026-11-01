package com.gym.backend.util

import com.gym.backend.model.Gym
import com.gym.backend.model.User
import com.gym.backend.model.UserRole
import com.gym.backend.repository.GymRepository
import com.gym.backend.repository.UserRepository
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.boot.CommandLineRunner
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Component

@Component
@ConditionalOnProperty(name = ["app.init-data.enabled"], havingValue = "true", matchIfMissing = false)
class DataInitializer(
    private val userRepository: UserRepository,
    private val gymRepository: GymRepository,
    private val passwordEncoder: PasswordEncoder,
    @Value("\${app.init-data.admin-email:admin@hkfitconnect.com}")
    private val adminEmail: String,
    @Value("\${app.init-data.admin-password:}")
    private val adminPassword: String,
    @Value("\${app.init-data.gym-name:HK Fit Connect Studio}")
    private val gymName: String
) : CommandLineRunner {

    private val logger = LoggerFactory.getLogger(DataInitializer::class.java)

    override fun run(vararg args: String?) {
        val gym = gymRepository.findByName(gymName) ?: gymRepository.save(
            Gym(
                name = gymName,
                primaryColor = "#8E44AD",
                logoUrl = "https://api.studionuz.com/logo.png"
            )
        )

        try {
            if (userRepository.findByEmail(adminEmail) == null) {
                if (adminPassword.isNotBlank()) {
                    val adminUser = User(
                        email = adminEmail,
                        passwordHash = passwordEncoder.encode(adminPassword.trim()),
                        fullName = "HK Admin",
                        role = UserRole.ADMIN,
                        gym = gym
                    )
                    userRepository.save(adminUser)
                    logger.info("Test/Seed Admin hesabı oluşturuldu ({})", adminEmail)
                } else {
                    logger.warn("app.init-data.enabled=true fakat INIT_DATA_ADMIN_PASSWORD boş bırakıldığı için varsayılan admin kullanıcısı oluşturulmadı.")
                }
            }
        } catch (e: Exception) {
            logger.error("Admin kullanıcısı oluşturulurken hata: {}", e.message)
        }
    }
}
