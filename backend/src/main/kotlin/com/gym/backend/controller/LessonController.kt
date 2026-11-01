package com.gym.backend.controller

import com.gym.backend.config.GlobalExceptionHandler
import com.gym.backend.service.BookingService
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.time.Instant
import java.time.ZoneId

@RestController
@RequestMapping("/api/lessons")
class LessonController(private val bookingService: BookingService) {

    @PostMapping("/verify-qr")
    fun verifyQr(
        @RequestParam(required = false) bookingId: Long?,
        @RequestParam trainerId: Long,
        @RequestParam(required = false) memberId: Long?,
        authentication: org.springframework.security.core.Authentication?
    ): ResponseEntity<Any> {
        return try {
            if (bookingId != null && bookingId > 0) {
                val message = bookingService.verifyAndCompleteLesson(bookingId, trainerId)
                ResponseEntity.ok(mapOf("message" to message))
            } else {
                val targetMemberId = memberId ?: run {
                    val email = authentication?.name ?: throw Exception("Kullanıcı doğrulanamadı!")
                    bookingService.findMemberByEmail(email)?.id ?: throw Exception("Üye bulunamadı!")
                }
                val booking = bookingService.startDirectLesson(trainerId, targetMemberId)
                ResponseEntity.ok(mapOf(
                    "message" to "Ders başlamıştır, iyi dersler! 🏋️‍♂️",
                    "bookingId" to booking.id
                ))
            }
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    @PostMapping("/start-direct")
    fun startDirect(
        @RequestParam trainerId: Long,
        @RequestParam memberId: Long,
        @RequestParam(required = false) lessonType: String?
    ): ResponseEntity<Any> {
        return try {
            val booking = bookingService.startDirectLesson(trainerId, memberId, lessonType)
            ResponseEntity.ok(mapOf(
                "message" to "Ders başarıyla başlatıldı ve üyenin kredisinden 1 seans düşüldü. İyi dersler! 🏋️‍♂️",
                "bookingId" to booking.id
            ))
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    @GetMapping("/latest-completed")
    fun getLatestCompleted(
        @RequestParam trainerId: Long,
        @RequestParam since: Long
    ): ResponseEntity<Any> {
        return try {
            val sinceTime = Instant.ofEpochMilli(since)
                .atZone(ZoneId.systemDefault())
                .toLocalDateTime()
                .minusSeconds(10)
            val latest = bookingService.getLatestCompletedSession(trainerId, sinceTime)
            if (latest != null) {
                ResponseEntity.ok(mapOf(
                    "completed" to true,
                    "bookingId" to latest.id,
                    "memberName" to latest.member.fullName
                ))
            } else {
                ResponseEntity.ok(mapOf("completed" to false))
            }
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }
}
