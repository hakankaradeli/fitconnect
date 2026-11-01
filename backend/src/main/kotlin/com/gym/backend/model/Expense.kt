package com.gym.backend.model

import jakarta.persistence.*
import java.time.LocalDate
import java.time.LocalDateTime

enum class ExpenseCategory {
    TRAINER_EARNINGS,   // Eğitmen hakediş ödemesi
    TRAINER_INSURANCE,  // Eğitmen sigorta primi
    TAX,                // Vergiler
    ELECTRICITY,        // Elektrik faturası
    WATER,              // Su faturası
    NATURAL_GAS,        // Doğalgaz faturası
    RENT,               // Kira
    ACCOUNTANT,         // Muhasebeci ücreti
    BAGKUR,             // Bağkur primi
    OTHER               // Diğer giderler
}

@Entity
@Table(name = "expenses")
class Expense(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "gym_id", nullable = false)
    val gym: Gym,

    @Enumerated(EnumType.STRING)
    val category: ExpenseCategory,

    val title: String,

    val amount: Double,

    val expenseDate: LocalDate,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "trainer_id")
    val trainer: User? = null,

    val notes: String? = null,

    val createdAt: LocalDateTime = LocalDateTime.now()
)
