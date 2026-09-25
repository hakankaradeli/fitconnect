package com.gym.backend.controller

import com.gym.backend.dto.LoginRequest
import com.gym.backend.service.AuthService
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/auth")
class AuthController(private val authService: AuthService) {

    @PostMapping("/login")
    fun login(@RequestBody request: LoginRequest): ResponseEntity<Any> {
        return try {
            val response = authService.authenticate(request)
            ResponseEntity.ok(response)
        } catch (e: Exception) {
            ResponseEntity.status(401).body(mapOf("error" to e.message))
        }
    }
}
