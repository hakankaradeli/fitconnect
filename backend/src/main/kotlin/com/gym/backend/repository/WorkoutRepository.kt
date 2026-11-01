package com.gym.backend.repository

import com.gym.backend.model.Workout
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface WorkoutRepository : JpaRepository<Workout, Long> {
    fun findByMemberId(memberId: Long): List<Workout>
}
