package com.gym.backend.repository

import com.gym.backend.model.Survey
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository

@Repository
interface SurveyRepository : JpaRepository<Survey, Long> {
    
    @Query("SELECT AVG(s.rating) FROM Survey s WHERE s.booking.trainer.id = :trainerId")
    fun getAverageRatingForTrainer(trainerId: Long): Double?

    @Query("SELECT s FROM Survey s WHERE s.booking.gym.id = :gymId AND (s.rating <= 2.0 OR (s.comment IS NOT NULL AND s.comment != '')) ORDER BY s.id DESC")
    fun findAllComplaintsByGymId(gymId: Long): List<Survey>
}
