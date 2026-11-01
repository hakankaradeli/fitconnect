package com.gym.backend.controller

import com.gym.backend.config.GlobalExceptionHandler
import com.gym.backend.model.PermissionType
import com.gym.backend.service.DelegationService
import org.springframework.format.annotation.DateTimeFormat
import org.springframework.http.ResponseEntity
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.web.bind.annotation.*
import java.time.LocalDateTime

data class DelegationRequest(
    val trainerId: Long,
    val gymId: Long,
    val permissionType: PermissionType,
    @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME)
    val startTime: LocalDateTime,
    @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME)
    val endTime: LocalDateTime
)

@RestController
@RequestMapping("/api/delegations")
@PreAuthorize("hasRole('ADMIN')")
class DelegationController(private val delegationService: DelegationService) {

    @PostMapping("/grant")
    fun delegate(@RequestBody request: DelegationRequest): ResponseEntity<Any> {
        return try {
            val delegation = delegationService.delegatePermission(
                request.trainerId,
                request.gymId,
                request.permissionType,
                request.startTime,
                request.endTime
            )
            ResponseEntity.ok(delegation)
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    @GetMapping("/gym/{gymId}")
    fun getGymDelegations(@PathVariable gymId: Long): ResponseEntity<Any> {
        return ResponseEntity.ok(delegationService.getAllDelegationsInGym(gymId))
    }

    @DeleteMapping("/{id}")
    fun revoke(@PathVariable id: Long): ResponseEntity<Any> {
        delegationService.revokePermission(id)
        return ResponseEntity.ok(mapOf("message" to "Yetki başarıyla geri alındı"))
    }
}
