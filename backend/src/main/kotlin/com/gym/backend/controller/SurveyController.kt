package com.gym.backend.controller

import com.gym.backend.config.GlobalExceptionHandler
import com.gym.backend.model.Survey
import com.gym.backend.repository.BookingRepository
import com.gym.backend.repository.SurveyRepository
import org.springframework.http.ResponseEntity
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.web.bind.annotation.*

data class SurveySubmitRequest(
    val bookingId: Long? = null,
    val trainerId: Long? = null,
    val memberId: Long? = null,
    val rating: Int,
    val comment: String? = null
)

@RestController
@RequestMapping("/api/surveys")
class SurveyController(
    private val surveyRepository: SurveyRepository,
    private val bookingRepository: BookingRepository
) {

    @PostMapping
    @PreAuthorize("hasAnyAuthority('ROLE_MEMBER', 'ROLE_ADMIN', 'ROLE_TRAINER')")
    fun submitSurvey(@RequestBody request: SurveySubmitRequest): ResponseEntity<Any> {
        return try {
            val booking = if (request.bookingId != null && request.bookingId > 0) {
                bookingRepository.findById(request.bookingId).orElse(null)
            } else if (request.memberId != null && request.memberId > 0) {
                val memberBookings = bookingRepository.findAllActiveByMemberId(request.memberId)
                if (request.trainerId != null && request.trainerId > 0) {
                    memberBookings.lastOrNull { it.trainer.id == request.trainerId }
                } else {
                    memberBookings.lastOrNull()
                }
            } else null

            if (booking == null) {
                return ResponseEntity.badRequest().body(mapOf("error" to "Değerlendirilecek ders bulunamadı."))
            }

            val survey = Survey(
                booking = booking,
                rating = request.rating.coerceIn(1, 5),
                comment = request.comment?.trim()?.ifBlank { null },
                gymId = booking.gym.id ?: 0L
            )
            surveyRepository.save(survey)
            ResponseEntity.ok(mapOf("message" to "Geri bildiriminiz başarıyla kaydedildi."))
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }
}
