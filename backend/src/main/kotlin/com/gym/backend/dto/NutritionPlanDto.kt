package com.gym.backend.dto

data class NutritionPlanDto(
    val dailyCalories: Int,
    val protein: Int,
    val carbs: Int,
    val fat: Int,
    val meals: List<String>
)
