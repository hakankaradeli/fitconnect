package com.gym.backend.config

import com.gym.backend.repository.UserRepository
import org.slf4j.LoggerFactory
import org.springframework.boot.CommandLineRunner
import org.springframework.core.annotation.Order
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Component
import org.springframework.transaction.annotation.Transactional

@Component
@Order(1)
class PasswordMigrationRunner(
    private val userRepository: UserRepository,
    private val passwordEncoder: PasswordEncoder
) : CommandLineRunner {

    private val logger = LoggerFactory.getLogger(PasswordMigrationRunner::class.java)

    @Transactional
    override fun run(vararg args: String?) {
        try {
            val allUsers = userRepository.findAll()
            var migratedCount = 0

            for (user in allUsers) {
                val currentHash = user.passwordHash
                val isBcrypt = isBcryptHash(currentHash)

                if (!isBcrypt && currentHash.isNotBlank()) {
                    val hashed = passwordEncoder.encode(currentHash.trim())
                    user.passwordHash = hashed
                    userRepository.save(user)
                    migratedCount++
                }
            }

            if (migratedCount > 0) {
                logger.info("=== BCrypt Şifre Migrasyonu: {} kullanıcının şifresi BCrypt formatına yükseltildi. ===", migratedCount)
            } else {
                logger.info("=== BCrypt Şifre Migrasyonu: Tüm kullanıcı şifreleri zaten BCrypt formatında. ===")
            }
        } catch (e: Exception) {
            logger.error("Şifre migrasyonu sırasında hata oluştu: ${e.message}", e)
        }
    }

    private fun isBcryptHash(hash: String?): Boolean {
        if (hash.isNullOrBlank()) return false
        return hash.startsWith("\$2a\$") || hash.startsWith("\$2b\$") || hash.startsWith("\$2y\$")
    }
}
