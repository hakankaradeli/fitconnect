package com.gym.backend.config

import com.gym.backend.model.*
import com.gym.backend.repository.*
import org.slf4j.LoggerFactory
import org.springframework.boot.CommandLineRunner
import org.springframework.stereotype.Component
import org.springframework.transaction.annotation.Transactional

@Component
class DataSeeder(
    private val gymRepository: GymRepository,
    private val userRepository: UserRepository,
    private val exerciseRepository: ExerciseRepository,
    private val appRegistrationRepository: AppRegistrationRepository,
    private val gymRegistrationRepository: GymRegistrationRepository,
    private val userConsentLogRepository: UserConsentLogRepository
) : CommandLineRunner {

    private val logger = LoggerFactory.getLogger(DataSeeder::class.java)

    @Transactional
    override fun run(vararg args: String?) {
        if (gymRepository.count() == 0L) {
            seedData()
        }
        backfillUserCreatedAt()
        backfillRegistrations()
    }

    private fun backfillRegistrations() {
        try {
            // 1. Gym App Registrations
            val allGyms = gymRepository.findAll()
            for (gym in allGyms) {
                val gymId = gym.id ?: continue
                if (!appRegistrationRepository.existsByGymIdAndEntityType(gymId, AppRegistrationEntityType.GYM)) {
                    val appReg = AppRegistration(
                        entityType = AppRegistrationEntityType.GYM,
                        gymId = gymId,
                        email = gym.email ?: "info@fitconnect.com",
                        fullNameOrTitle = gym.name,
                        role = "GYM",
                        registeredAt = gym.createdAt
                    )
                    appRegistrationRepository.save(appReg)
                    logger.info("Salon için AppRegistration oluşturuldu: {}", gym.name)
                }
            }

            // 2. User App Registrations & Gym Registrations
            val allUsers = userRepository.findAll()
            for (user in allUsers) {
                val userId = user.id ?: continue
                val consent = userConsentLogRepository.findFirstByUserIdOrderByCreatedAtAsc(userId)
                val regDate = consent?.createdAt ?: user.createdAt ?: java.time.LocalDateTime.now()

                // Uygulamaya Kayıt (app_registrations)
                if (!appRegistrationRepository.existsByUserId(userId)) {
                    val appReg = AppRegistration(
                        entityType = AppRegistrationEntityType.USER,
                        userId = userId,
                        gymId = user.gym?.id,
                        email = user.email,
                        fullNameOrTitle = user.fullName,
                        role = user.role.name,
                        registeredAt = regDate
                    )
                    appRegistrationRepository.save(appReg)
                    logger.info("Kullanıcı için AppRegistration oluşturuldu: {}", user.fullName)
                }

                // Salona Kayıt (gym_registrations)
                val gym = user.gym
                if (gym?.id != null) {
                    if (!gymRegistrationRepository.existsByGymIdAndUserId(gym.id, userId)) {
                        val gymReg = GymRegistration(
                            gym = gym,
                            user = user,
                            role = user.role,
                            registeredAt = regDate,
                            isActive = user.isActive ?: true
                        )
                        gymRegistrationRepository.save(gymReg)
                        logger.info("Kullanıcı için GymRegistration oluşturuldu: {} -> {}", user.fullName, gym.name)
                    }
                }
            }
        } catch (e: Exception) {
            logger.warn("Registrations backfill sırasında hata: {}", e.message)
        }
    }

    private fun backfillUserCreatedAt() {
        try {
            val allUsers = userRepository.findAll()
            var count = 0
            allUsers.forEach { u ->
                val uid = u.id ?: return@forEach
                if (u.createdAt == null) {
                    val consent = userConsentLogRepository.findFirstByUserIdOrderByCreatedAtAsc(uid)
                    u.createdAt = consent?.createdAt ?: java.time.LocalDateTime.now()
                    userRepository.save(u)
                    count++
                }
            }
            if (count > 0) {
                logger.info("Backfilled createdAt for {} users from consent logs", count)
            }
        } catch (e: Exception) {
            logger.warn("Could not backfill createdAt: {}", e.message)
        }
    }

    private fun seedData() {
        // 1. Gym Oluştur
        val fitGym = Gym(
            name = "FitConnect Elite Salonu",
            address = "Merkez Mah. No:1, İstanbul",
            primaryColor = "#1E88E5",
            logoUrl = "https://example.com/logo.png"
        )
        val savedGym = gymRepository.save(fitGym)
        appRegistrationRepository.save(AppRegistration(
            entityType = AppRegistrationEntityType.GYM,
            gymId = savedGym.id,
            email = "info@fitconnect.com",
            fullNameOrTitle = savedGym.name,
            role = "GYM",
            registeredAt = savedGym.createdAt
        ))

        // 2. Admin Kullanıcı Oluştur
        val admin = User(
            email = "admin@fitconnect.com",
            passwordHash = "4172", // Şimdilik düz metin (AuthService ile uyumlu)
            fullName = "Hakan Admin",
            phone = "+90 555 123 45 67",
            role = UserRole.ADMIN,
            gym = savedGym,
            isActive = true
        )
        val savedAdmin = userRepository.save(admin)
        appRegistrationRepository.save(AppRegistration(
            entityType = AppRegistrationEntityType.USER,
            userId = savedAdmin.id,
            gymId = savedGym.id,
            email = savedAdmin.email,
            fullNameOrTitle = savedAdmin.fullName,
            role = "ADMIN",
            registeredAt = savedAdmin.createdAt ?: java.time.LocalDateTime.now()
        ))
        gymRegistrationRepository.save(GymRegistration(
            gym = savedGym,
            user = savedAdmin,
            role = UserRole.ADMIN,
            registeredAt = savedAdmin.createdAt ?: java.time.LocalDateTime.now(),
            isActive = true
        ))

        // 3. Eğitmen Oluştur
        val trainer = User(
            email = "trainer@fitconnect.com",
            passwordHash = "4172",
            fullName = "Eğitmen Mert",
            phone = "+90 555 987 65 43",
            role = UserRole.TRAINER,
            gym = savedGym,
            isActive = true,
            canTeach = listOf("PT_1TO1", "REFORMER_GROUP")
        )
        val savedTrainer = userRepository.save(trainer)
        appRegistrationRepository.save(AppRegistration(
            entityType = AppRegistrationEntityType.USER,
            userId = savedTrainer.id,
            gymId = savedGym.id,
            email = savedTrainer.email,
            fullNameOrTitle = savedTrainer.fullName,
            role = "TRAINER",
            registeredAt = savedTrainer.createdAt ?: java.time.LocalDateTime.now()
        ))
        gymRegistrationRepository.save(GymRegistration(
            gym = savedGym,
            user = savedTrainer,
            role = UserRole.TRAINER,
            registeredAt = savedTrainer.createdAt ?: java.time.LocalDateTime.now(),
            isActive = true
        ))

        // 4. Temel Egzersizleri Oluştur
        val exercises = listOf(
            Exercise(name = "Push-up", category = "Chest", description = "Standard push-up for chest and triceps", gym = savedGym),
            Exercise(name = "Squat", category = "Legs", description = "Bodyweight squat for quads and glutes", gym = savedGym),
            Exercise(name = "Lat Pulldown", category = "Back", description = "Machine lat pulldown for back width", gym = savedGym),
            Exercise(name = "Shoulder Press", category = "Shoulders", description = "Dumbbell press for deltoids", gym = savedGym),
            Exercise(name = "Plank", category = "Core", description = "Static hold for core stability", gym = savedGym)
        )
        exerciseRepository.saveAll(exercises)

        logger.info("Veritabanı başlangıç verileri başarıyla yüklendi.")
    }
}
