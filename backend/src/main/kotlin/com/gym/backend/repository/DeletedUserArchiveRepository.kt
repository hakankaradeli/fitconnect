package com.gym.backend.repository

import com.gym.backend.model.DeletedUserArchive
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository
import java.time.LocalDateTime

@Repository
interface DeletedUserArchiveRepository : JpaRepository<DeletedUserArchive, Long> {
    fun findAllByOrderByDeletedAtDesc(): List<DeletedUserArchive>
    fun deleteAllByRetentionPurgeDateBefore(now: LocalDateTime): Int
}
