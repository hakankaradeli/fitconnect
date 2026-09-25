package com.gym.backend.repository

import com.gym.backend.model.MemberCredit
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface MemberCreditRepository : JpaRepository<MemberCredit, Long> {
    fun findByMemberId(memberId: Long): MemberCredit?
}
