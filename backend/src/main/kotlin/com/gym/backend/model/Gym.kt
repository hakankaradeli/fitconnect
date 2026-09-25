package com.gym.backend.model

import jakarta.persistence.*

@Entity
@Table(name = "gyms")
class Gym(
    @Id 
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @Column(nullable = false)
    val name: String,

    val address: String? = null,

    val logoUrl: String? = null,
    
    @Column(length = 7)
    val primaryColor: String? = "#3F51B5" // Varsayılan renk
)
