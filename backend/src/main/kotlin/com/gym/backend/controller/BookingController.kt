package com.gym.backend.controller

import com.gym.backend.config.GlobalExceptionHandler
import com.gym.backend.dto.BookingRequest
import com.gym.backend.dto.BulkBookingRequest
import com.gym.backend.model.Booking
import com.gym.backend.service.BookingService
import org.slf4j.LoggerFactory
import org.springframework.format.annotation.DateTimeFormat
import org.springframework.http.ResponseEntity
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.web.bind.annotation.*
import java.time.LocalDateTime

@RestController
@RequestMapping("/api/bookings")
class BookingController(private val bookingService: BookingService) {

    private val logger = LoggerFactory.getLogger(BookingController::class.java)

    @PostMapping("/create")
    fun makeAppointment(
        @RequestBody request: BookingRequest,
        authentication: org.springframework.security.core.Authentication?
    ): ResponseEntity<Any> {
        return try {
            val isAdmin = authentication?.authorities?.any { it.authority == "ROLE_ADMIN" || it.authority == "ROLE_SUPER_ADMIN" } ?: false
            
            val booking = bookingService.createBooking(
                request.memberId, 
                request.trainerId, 
                request.gymId, 
                request.startTime,
                ignoreRules = isAdmin
            )
            ResponseEntity.ok(booking)
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    @PostMapping("/create-bulk")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'PERM_MANAGE_SCHEDULE')")
    fun makeBulkAppointments(
        @RequestBody request: BulkBookingRequest,
        authentication: org.springframework.security.core.Authentication?
    ): ResponseEntity<Any> {
        return try {
            val isAdmin = authentication?.authorities?.any { it.authority == "ROLE_ADMIN" || it.authority == "ROLE_SUPER_ADMIN" } ?: false
            
            val bookings = bookingService.createBulkBookings(
                request.memberId,
                request.trainerId,
                request.gymId,
                request.startTimes,
                ignoreRules = isAdmin
            )
            ResponseEntity.ok(bookings)
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    @GetMapping("/trainer-schedule/{trainerId}")
    @PreAuthorize("hasAnyAuthority('ROLE_TRAINER', 'ROLE_ADMIN')")
    fun getSchedule(
        @PathVariable trainerId: Long,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) start: LocalDateTime,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) end: LocalDateTime
    ): ResponseEntity<Any> {
        return try {
            logger.debug("Ders programı isteği: TrainerId={}, Start={}, End={}", trainerId, start, end)
            val schedule = bookingService.getTrainerSchedule(trainerId, start, end)
            ResponseEntity.ok(schedule)
        } catch (e: Exception) {
            logger.error("Ders programı yükleme hatası: {}", e.message, e)
            ResponseEntity.status(500).body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    @GetMapping("/gym-schedule/{gymId}")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'ADMIN', 'ROLE_SUPER_ADMIN', 'SUPER_ADMIN')")
    fun getGymSchedule(
        @PathVariable gymId: Long,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) start: LocalDateTime,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) end: LocalDateTime
    ): ResponseEntity<Any> {
        return try {
            val schedule = bookingService.getGymWeeklySchedule(gymId, start, end)
            ResponseEntity.ok(schedule)
        } catch (e: Exception) {
            logger.error("Salon haftalık program yükleme hatası: {}", e.message, e)
            ResponseEntity.status(500).body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    @PutMapping("/propose/{bookingId}")
    @PreAuthorize("hasAnyAuthority('ROLE_MEMBER', 'ROLE_ADMIN', 'PERM_MANAGE_SCHEDULE')")
    fun proposeChange(
        @PathVariable bookingId: Long,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) newStartTime: LocalDateTime
    ): ResponseEntity<Any> {
        return try {
            val auth = org.springframework.security.core.context.SecurityContextHolder.getContext().authentication
            val isByAdmin = auth.authorities.any { it.authority == "ROLE_ADMIN" || it.authority == "PERM_MANAGE_SCHEDULE" }
            
            val booking = bookingService.proposeBookingChange(bookingId, newStartTime, isByAdmin)
            ResponseEntity.ok(booking)
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    @PutMapping("/refund/{bookingId}")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'PERM_MANAGE_SCHEDULE')")
    fun refundCompletedBooking(@PathVariable bookingId: Long): ResponseEntity<Any> {
        return try {
            val booking = bookingService.refundCompletedBooking(bookingId)
            ResponseEntity.ok(booking)
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    @PutMapping("/approve/{bookingId}")
    @PreAuthorize("hasRole('MEMBER')")
    fun approveBooking(@PathVariable bookingId: Long): ResponseEntity<Any> {
        return try {
            val booking = bookingService.approveBooking(bookingId)
            ResponseEntity.ok(booking)
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    @PutMapping("/reject/{bookingId}")
    fun rejectBooking(
        @PathVariable bookingId: Long,
        @RequestParam(required = false) cancelledById: Long?,
        @RequestParam(required = false) reason: String?
    ): ResponseEntity<Any> {
        return try {
            val booking = bookingService.rejectBooking(bookingId, cancelledById, reason)
            ResponseEntity.ok(booking)
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    @GetMapping("/reports/top-cancelled-members")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'PERM_VIEW_REPORTS')")
    fun getTopCancelledMembers(): ResponseEntity<Any> {
        return ResponseEntity.ok(bookingService.getMostCancelledMember())
    }

    @GetMapping("/reports/top-cancelled-trainers-by-others")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'PERM_VIEW_REPORTS')")
    fun getTopCancelledTrainersByOthers(): ResponseEntity<Any> {
        return ResponseEntity.ok(bookingService.getMostCancelledTrainerByOthers())
    }

    @GetMapping("/reports/top-cancelling-trainers")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'PERM_VIEW_REPORTS')")
    fun getTopCancellingTrainers(): ResponseEntity<Any> {
        return ResponseEntity.ok(bookingService.getMostCancellingTrainer())
    }

    @PutMapping("/change-trainer/{bookingId}")
    @PreAuthorize("hasAnyAuthority('ROLE_MEMBER', 'ROLE_ADMIN', 'PERM_MANAGE_SCHEDULE')")
    fun changeTrainer(
        @PathVariable bookingId: Long,
        @RequestParam newTrainerId: Long
    ): ResponseEntity<Any> {
        return try {
            // Basitlik için: Eğer bu endpoint Admin rolü yetkisiyle çağrılıyorsa isByAdmin true
            // (Güvenlik bağlamından rol kontrolü yapılır)
            val auth = org.springframework.security.core.context.SecurityContextHolder.getContext().authentication
            val isByAdmin = auth.authorities.any { it.authority == "ROLE_ADMIN" || it.authority == "PERM_MANAGE_SCHEDULE" }

            val booking = bookingService.changeBookingTrainer(bookingId, newTrainerId, isByAdmin)
            ResponseEntity.ok(booking)
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    @GetMapping("/member-history/{memberId}")
    fun getMemberHistory(@PathVariable memberId: Long): ResponseEntity<Any> {
        return try {
            val history = bookingService.getMemberBookings(memberId)
            ResponseEntity.ok(history)
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    @GetMapping("/trainer-pending/{trainerId}")
    @PreAuthorize("hasAnyAuthority('ROLE_TRAINER', 'ROLE_ADMIN')")
    fun getTrainerPending(@PathVariable trainerId: Long): ResponseEntity<Any> {
        return try {
            val pending = bookingService.getPendingTrainerBookings(trainerId)
            ResponseEntity.ok(pending)
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    @PutMapping("/trainer-approve/{bookingId}")
    @PreAuthorize("hasAnyAuthority('ROLE_TRAINER', 'ROLE_ADMIN')")
    fun trainerApprove(@PathVariable bookingId: Long): ResponseEntity<Any> {
        return try {
            val booking = bookingService.approveBooking(bookingId)
            ResponseEntity.ok(booking)
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    @PutMapping("/trainer-reject/{bookingId}")
    @PreAuthorize("hasAnyAuthority('ROLE_TRAINER', 'ROLE_ADMIN')")
    fun trainerReject(
        @PathVariable bookingId: Long,
        @RequestParam(required = false) reason: String?,
        @RequestParam(required = false, defaultValue = "false") isDirectCancel: Boolean
    ): ResponseEntity<Any> {
        return try {
            val user = bookingService.trainerRejectBooking(bookingId, 0L, reason, isDirectCancel)
            ResponseEntity.ok(user)
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    @GetMapping("/admin-pending/{gymId}")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'PERM_MANAGE_SCHEDULE')")
    fun getAdminPending(@PathVariable gymId: Long): ResponseEntity<Any> {
        return try {
            val pendingList = bookingService.getAdminPendingBookings(gymId)
            ResponseEntity.ok(pendingList)
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    @GetMapping("/{bookingId}")
    fun getBookingById(@PathVariable bookingId: Long): ResponseEntity<Any> {
        return try {
            val booking = bookingService.getBookingById(bookingId)
            ResponseEntity.ok(booking)
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    @PutMapping("/confirm-attendance/{bookingId}")
    @PreAuthorize("hasAnyAuthority('ROLE_MEMBER', 'ROLE_ADMIN')")
    fun confirmAttendance(
        @PathVariable bookingId: Long,
        @RequestParam willAttend: Boolean
    ): ResponseEntity<Any> {
        return try {
            val booking = bookingService.confirmAttendance(bookingId, willAttend)
            ResponseEntity.ok(booking)
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    @GetMapping("/available-slots")
    fun getAvailableSlots(
        @RequestParam trainerId: Long,
        @RequestParam gymId: Long,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) date: java.time.LocalDate
    ): ResponseEntity<Any> {
        return try {
            val slots = bookingService.getAvailableSlots(trainerId, gymId, date)
            ResponseEntity.ok(slots)
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    @GetMapping("/available-trainers")
    fun getAvailableTrainers(
        @RequestParam gymId: Long,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) startTime: LocalDateTime
    ): ResponseEntity<Any> {
        return try {
            val trainers = bookingService.getAvailableTrainersForSlot(gymId, startTime)
            ResponseEntity.ok(trainers)
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    @PostMapping("/{bookingId}/exercises")
    @PreAuthorize("hasAnyAuthority('ROLE_TRAINER', 'ROLE_ADMIN')")
    fun addExercises(
        @PathVariable bookingId: Long,
        @RequestBody exercises: List<com.gym.backend.dto.PerformedExerciseRequest>
    ): ResponseEntity<Any> {
        return try {
            val booking = bookingService.addPerformedExercises(bookingId, exercises)
            ResponseEntity.ok(booking)
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }
}
