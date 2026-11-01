package com.gym.backend.model

import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "gyms")
class Gym(
    @Id 
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @Column(nullable = false)
    var name: String,

    var address: String? = null,

    var phone: String? = null,

    var email: String? = null,

    var instagram: String? = null,

    var website: String? = null,

    @Column(columnDefinition = "TEXT")
    var logoUrl: String? = null,
    
    @Column(length = 7)
    var primaryColor: String? = "#3F51B5",

    @Column(length = 7, nullable = true)
    var secondaryColor: String? = "#00BFA5",

    @Column(name = "is_gradient", nullable = true)
    var isGradient: Boolean? = false,

    @Column(name = "is_active", nullable = true)
    var isActive: Boolean? = true,

    @Column(name = "working_days", nullable = true)
    var workingDays: String? = "1,2,3,4,5,6", // Pazartesi(1) - Cumartesi(6)

    @Column(name = "open_time", nullable = true)
    var openTime: String? = "07:00",

    @Column(name = "close_time", nullable = true)
    var closeTime: String? = "22:00",

    @Column(name = "max_cancellations_allowed", nullable = true)
    var maxCancellationsAllowed: Int? = 4,

    @Column(name = "offered_lesson_groups", nullable = true)
    var offeredLessonGroups: String? = "PT,Pilates,Kickboks,Yoga",

    val createdAt: LocalDateTime = LocalDateTime.now()
)
