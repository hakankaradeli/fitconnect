package com.gym.backend.repository

import com.gym.backend.model.LeaveRecord
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface LeaveRecordRepository : JpaRepository<LeaveRecord, Long> {
    fun findAllByTrainerIdOrderByStartDateDesc(trainerId: Long): List<LeaveRecord>
}
