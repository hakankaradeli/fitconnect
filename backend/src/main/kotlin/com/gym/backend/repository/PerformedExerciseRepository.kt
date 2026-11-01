package com.gym.backend.repository

import com.gym.backend.model.PerformedExercise
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface PerformedExerciseRepository : JpaRepository<PerformedExercise, Long> {
    fun findAllByBookingId(bookingId: Long): List<PerformedExercise>
}
