package com.gym.backend.controller

import com.gym.backend.dto.UserCreateRequest
import com.gym.backend.service.UserService
import org.springframework.http.ResponseEntity
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/users")
class UserController(private val userService: UserService) {

    @PostMapping("/create")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'PERM_MANAGE_USERS')")
    fun createUser(@RequestBody request: UserCreateRequest): ResponseEntity<Any> {
        return try {
            userService.createUser(request)
            ResponseEntity.ok(mapOf("message" to "Üye başarıyla oluşturuldu"))
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to e.message))
        }
    }

    @GetMapping("/list/{gymId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'MEMBER')")
    fun getUsers(@PathVariable gymId: Long): ResponseEntity<Any> {
        return try {
            val users = userService.getUsersByGym(gymId)
            ResponseEntity.ok(users)
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to e.message))
        }
    }

    @GetMapping("/deleted/{gymId}")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'PERM_MANAGE_USERS')")
    fun getDeletedUsers(@PathVariable gymId: Long): ResponseEntity<Any> {
        return try {
            val users = userService.getDeletedUsersByGym(gymId)
            ResponseEntity.ok(users)
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to e.message))
        }
    }

    @GetMapping("/profile/{userId}")
    @PreAuthorize("hasAnyAuthority('ROLE_MEMBER', 'ROLE_TRAINER', 'ROLE_ADMIN')")
    fun getProfile(@PathVariable userId: Long): ResponseEntity<Any> {
        return try {
            val user = userService.getUserById(userId)
            ResponseEntity.ok(mapOf(
                "userId" to user.id,
                "fullName" to user.fullName,
                "firstName" to user.firstName,
                "lastName" to user.lastName,
                "email" to user.email,
                "phone" to user.phone,
                "birthDate" to user.birthDate?.toString(),
                "gender" to user.gender,
                "role" to user.role.name,
                "profileImageUrl" to user.profileImageUrl,
                "instagram" to user.instagram,
                "linkedin" to user.linkedin,
                "twitter" to user.twitter
            ))
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to e.message))
        }
    }

    @PutMapping("/profile/{userId}")
    @PreAuthorize("hasAnyAuthority('ROLE_MEMBER', 'ROLE_TRAINER', 'ROLE_ADMIN')")
    fun updateProfile(
        @PathVariable userId: Long,
        @RequestBody request: com.gym.backend.dto.UpdateProfileRequest
    ): ResponseEntity<Any> {
        return try {
            val updatedUser = userService.updateProfile(userId, request)
            ResponseEntity.ok(mapOf(
                "message" to "Profil başarıyla güncellendi",
                "userId" to updatedUser.id,
                "fullName" to updatedUser.fullName,
                "firstName" to updatedUser.firstName,
                "lastName" to updatedUser.lastName,
                "email" to updatedUser.email,
                "phone" to updatedUser.phone,
                "birthDate" to updatedUser.birthDate?.toString(),
                "gender" to updatedUser.gender,
                "profileImageUrl" to updatedUser.profileImageUrl,
                "instagram" to updatedUser.instagram,
                "linkedin" to updatedUser.linkedin,
                "twitter" to updatedUser.twitter
            ))
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to e.message))
        }
    }

    @PutMapping("/update-assignment/{memberId}")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'PERM_MANAGE_USERS')")
    fun updateAssignment(
        @PathVariable memberId: Long,
        @RequestParam(required = false) trainerId: Long?,
        @RequestParam(required = false) lessonType: String?
    ): ResponseEntity<Any> {
        return try {
            val updatedUser = userService.updateMemberAssignment(memberId, trainerId, lessonType)
            ResponseEntity.ok(updatedUser)
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to e.message))
        }
    }

    @PutMapping("/update-can-teach/{trainerId}")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'PERM_MANAGE_USERS')")
    fun updateTrainerCanTeach(
        @PathVariable trainerId: Long,
        @RequestBody canTeach: List<String>
    ): ResponseEntity<Any> {
        return try {
            val updatedUser = userService.updateTrainerCanTeach(trainerId, canTeach)
            ResponseEntity.ok(updatedUser)
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to e.message))
        }
    }

    @PutMapping("/freeze-member/{memberId}")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'PERM_MANAGE_USERS')")
    fun freezeMember(
        @PathVariable memberId: Long,
        @RequestParam @org.springframework.format.annotation.DateTimeFormat(iso = org.springframework.format.annotation.DateTimeFormat.ISO.DATE) start: java.time.LocalDate,
        @RequestParam @org.springframework.format.annotation.DateTimeFormat(iso = org.springframework.format.annotation.DateTimeFormat.ISO.DATE) end: java.time.LocalDate,
        @RequestParam(required = false) reason: String?
    ): ResponseEntity<Any> {
        return try {
            val updatedUser = userService.freezeMember(memberId, start, end, reason)
            ResponseEntity.ok(updatedUser)
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to e.message))
        }
    }

    @PutMapping("/unfreeze-member/{memberId}")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'PERM_MANAGE_USERS')")
    fun unfreezeMember(@PathVariable memberId: Long): ResponseEntity<Any> {
        return try {
            val updatedUser = userService.unfreezeMember(memberId)
            ResponseEntity.ok(updatedUser)
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to e.message))
        }
    }

    @DeleteMapping("/{userId}")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'PERM_MANAGE_USERS')")
    fun deleteUser(
        @PathVariable userId: Long,
        @RequestParam(required = false) replacementTrainerId: Long?
    ): ResponseEntity<Any> {
        return try {
            userService.deleteUser(userId, replacementTrainerId)
            ResponseEntity.ok(mapOf("message" to "Kullanıcı başarıyla silindi"))
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to e.message))
        }
    }

    @PutMapping("/toggle-status/{userId}")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'PERM_MANAGE_USERS')")
    fun toggleStatus(
        @PathVariable userId: Long,
        @RequestParam(required = false) replacementTrainerId: Long?
    ): ResponseEntity<Any> {
        return try {
            val updatedUser = userService.toggleUserStatus(userId, replacementTrainerId)
            ResponseEntity.ok(updatedUser)
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to e.message))
        }
    }

    @PutMapping("/set-leave/{userId}")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'PERM_MANAGE_USERS')")
    fun setLeave(
        @PathVariable userId: Long,
        @RequestParam @org.springframework.format.annotation.DateTimeFormat(iso = org.springframework.format.annotation.DateTimeFormat.ISO.DATE_TIME) start: java.time.LocalDateTime,
        @RequestParam @org.springframework.format.annotation.DateTimeFormat(iso = org.springframework.format.annotation.DateTimeFormat.ISO.DATE_TIME) end: java.time.LocalDateTime,
        @RequestParam(required = false) replacementTrainerId: Long?
    ): ResponseEntity<Any> {
        return try {
            val updatedUser = userService.setTrainerLeave(userId, start, end, replacementTrainerId)
            ResponseEntity.ok(updatedUser)
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to e.message))
        }
    }

    @GetMapping("/leave-history/{trainerId}")
    @PreAuthorize("hasRole('ADMIN')")
    fun getLeaveHistory(@PathVariable trainerId: Long): ResponseEntity<Any> {
        return ResponseEntity.ok(userService.getTrainerLeaveHistory(trainerId))
    }

    @DeleteMapping("/cancel-leave/{leaveId}")
    @PreAuthorize("hasRole('ADMIN')")
    fun cancelLeave(@PathVariable leaveId: Long): ResponseEntity<Any> {
        return try {
            userService.cancelLeave(leaveId)
            ResponseEntity.ok(mapOf("message" to "İzin iptal edildi"))
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to e.message))
        }
    }
}
