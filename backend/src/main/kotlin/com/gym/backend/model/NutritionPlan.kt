package com.gym.backend.model

import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "nutrition_plans")
class NutritionPlan(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "member_id", nullable = false)
    val member: User,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "trainer_id", nullable = false)
    val trainer: User,

    val dailyCalories: Int,
    val protein: Int,
    val carbs: Int,
    val fat: Int,

    @ElementCollection // Öğün listesini basit bir tablo olarak tutar
    @CollectionTable(name = "plan_meals", joinColumns = [JoinColumn(name = "plan_id")])
    @Column(name = "meal_description")
    val meals: List<String> = mutableListOf(),

    val createdAt: LocalDateTime = LocalDateTime.now(),

    // PRD Gereksinimi: 60 günlük periyot (Otomatik hesaplanır)
    val expiryDate: LocalDateTime = LocalDateTime.now().plusDays(60)
)
