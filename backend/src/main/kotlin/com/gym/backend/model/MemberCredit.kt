package com.gym.backend.model

import jakarta.persistence.*

@Entity
@Table(name = "member_credits")
class MemberCredit(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @OneToOne
    @JoinColumn(name = "member_id", nullable = false)
    val member: User,

    var totalPurchased: Int = 0,
    var totalUsed: Int = 0
) {
    // PRD Gereksinimi: Eksi bakiye (Avans) kullanımına izin verir
    @get:Transient
    val netBalance: Int
        get() = totalPurchased - totalUsed
}
