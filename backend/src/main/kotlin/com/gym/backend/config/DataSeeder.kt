package com.gym.backend.config

import com.gym.backend.model.*
import com.gym.backend.repository.*
import org.springframework.boot.CommandLineRunner
import org.springframework.stereotype.Component
import org.springframework.transaction.annotation.Transactional

@Component
class DataSeeder(
    private val gymRepository: GymRepository,
    private val userRepository: UserRepository,
    private val exerciseRepository: ExerciseRepository
) : CommandLineRunner {

    @Transactional
    override fun run(vararg args: String?) {
        if (gymRepository.count() == 0L) {
            seedData()
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
        userRepository.save(admin)

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
        userRepository.save(trainer)

        // 4. Temel Egzersizleri Oluştur
        val exercises = listOf(
            Exercise(name = "Push-up", category = "Chest", description = "Standard push-up for chest and triceps", gym = savedGym),
            Exercise(name = "Squat", category = "Legs", description = "Bodyweight squat for quads and glutes", gym = savedGym),
            Exercise(name = "Lat Pulldown", category = "Back", description = "Machine lat pulldown for back width", gym = savedGym),
            Exercise(name = "Shoulder Press", category = "Shoulders", description = "Dumbbell press for deltoids", gym = savedGym),
            Exercise(name = "Plank", category = "Core", description = "Static hold for core stability", gym = savedGym)
        )
        exerciseRepository.saveAll(exercises)

        println(">> Veritabanı başlangıç verileri başarıyla yüklendi.")
    }
}
