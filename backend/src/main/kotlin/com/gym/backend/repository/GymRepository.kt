package com.gym.backend.repository

import com.gym.backend.model.Gym
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface GymRepository : JpaRepository<Gym, Long> {
    fun findByName(name: String): Gym?
}
