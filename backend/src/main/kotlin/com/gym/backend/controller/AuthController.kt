package com.gym.backend.controller

import com.gym.backend.config.GlobalExceptionHandler
import com.gym.backend.dto.LoginRequest
import com.gym.backend.dto.RefreshTokenRequest
import com.gym.backend.dto.RegisterRequest
import com.gym.backend.service.AuthService
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/auth")
class AuthController(private val authService: AuthService) {

    @GetMapping("/public-gyms")
    fun getPublicGyms(): ResponseEntity<Any> {
        return ResponseEntity.ok(authService.getPublicGyms())
    }

    @PostMapping("/register")
    fun register(
        @RequestBody request: RegisterRequest,
        servletRequest: jakarta.servlet.http.HttpServletRequest
    ): ResponseEntity<Any> {
        return try {
            val xForwardedFor = servletRequest.getHeader("X-Forwarded-For")
            val clientIp = if (!xForwardedFor.isNullOrBlank()) {
                xForwardedFor.split(",").first().trim()
            } else {
                servletRequest.remoteAddr
            }

            val userAgent = servletRequest.getHeader("User-Agent")

            val enrichedRequest = request.copy(
                ipAddress = request.ipAddress ?: clientIp,
                deviceInfo = request.deviceInfo ?: userAgent
            )

            val response = authService.register(enrichedRequest)
            ResponseEntity.ok(response)
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    @PostMapping("/login")
    fun login(@RequestBody request: LoginRequest): ResponseEntity<Any> {
        return try {
            val response = authService.authenticate(request)
            ResponseEntity.ok(response)
        } catch (e: Exception) {
            ResponseEntity.status(401).body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }

    @PostMapping("/refresh")
    fun refreshToken(@RequestBody request: RefreshTokenRequest): ResponseEntity<Any> {
        return try {
            val response = authService.refreshToken(request.refreshToken)
            ResponseEntity.ok(response)
        } catch (e: Exception) {
            ResponseEntity.status(401).body(mapOf("error" to GlobalExceptionHandler.sanitizeMessage(e)))
        }
    }
}
