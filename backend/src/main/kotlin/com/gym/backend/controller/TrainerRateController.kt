package com.gym.backend.controller

import com.gym.backend.dto.TrainerRateUpdateDto
import com.gym.backend.model.TrainerRate
import com.gym.backend.repository.TrainerRateRepository
import com.gym.backend.repository.UserRepository
import org.springframework.http.ResponseEntity
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/trainer-rates")
class TrainerRateController(
    private val trainerRateRepository: TrainerRateRepository,
    private val userRepository: UserRepository
) {

    @GetMapping("/{trainerId}")
    @PreAuthorize("hasRole('ADMIN')")
    fun getRates(@PathVariable trainerId: Long): ResponseEntity<List<TrainerRate>> {
        return ResponseEntity.ok(trainerRateRepository.findAllByTrainerId(trainerId))
    }

    @PostMapping("/{trainerId}")
    @PreAuthorize("hasRole('ADMIN')")
    @Transactional
    fun updateRate(
        @PathVariable trainerId: Long,
        @RequestBody dto: TrainerRateUpdateDto
    ): ResponseEntity<Any> {
        val trainer = userRepository.findById(trainerId).orElseThrow { Exception("Eğitmen bulunamadı") }
        
        val existingRate = trainerRateRepository.findByTrainerIdAndLessonType(trainerId, dto.lessonType)
        
        if (existingRate != null) {
            existingRate.amount = dto.amount
            trainerRateRepository.save(existingRate)
        } else {
            val newRate = TrainerRate(
                trainer = trainer,
                lessonType = dto.lessonType,
                amount = dto.amount,
                gymId = dto.gymId
            )
            trainerRateRepository.save(newRate)
        }
        
        return ResponseEntity.ok(mapOf("message" to "Hakediş tutarı güncellendi"))
    }
}
