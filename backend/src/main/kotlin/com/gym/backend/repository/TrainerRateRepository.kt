package com.gym.backend.repository

import com.gym.backend.model.TrainerRate
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface TrainerRateRepository : JpaRepository<TrainerRate, Long> {
    fun findAllByTrainerId(trainerId: Long): List<TrainerRate>
    fun findByTrainerIdAndLessonType(trainerId: Long, lessonType: String): TrainerRate?
}
