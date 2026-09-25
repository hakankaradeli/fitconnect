package com.gym.backend.repository

import com.gym.backend.model.Exercise
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface ExerciseRepository : JpaRepository<Exercise, Long> {
    fun findByName(name: String): Exercise?
}
