package com.gym.backend.controller

import com.gym.backend.service.BookingService
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/lessons")
class LessonController(private val bookingService: BookingService) {

    @PostMapping("/verify-qr")
    fun verifyQr(
        @RequestParam bookingId: Long,
        @RequestParam trainerId: Long
    ): ResponseEntity<Any> {
        return try {
            val message = bookingService.verifyAndCompleteLesson(bookingId, trainerId)
            ResponseEntity.ok(mapOf("message" to message))
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to e.message))
        }
    }
}
