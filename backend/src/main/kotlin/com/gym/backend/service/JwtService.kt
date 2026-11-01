package com.gym.backend.service

import io.jsonwebtoken.Jwts
import io.jsonwebtoken.SignatureAlgorithm
import io.jsonwebtoken.security.Keys
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service
import java.nio.charset.StandardCharsets
import java.security.Key
import java.util.Date

@Service
class JwtService(
    @Value("\${jwt.secret:fitconnect-super-secure-and-ultra-resilient-jwt-secret-key-2026-production-ready-key-minimum-256-bits}")
    private val secret: String,
    @Value("\${jwt.expiration:1800000}")
    private val expirationTime: Long = 1800000L, // 30 dakika (milisaniye)
    @Value("\${jwt.refresh-expiration:2592000000}")
    private val refreshExpirationTime: Long = 2592000000L // 30 gün (milisaniye)
) {
    private val secretKey: Key = Keys.hmacShaKeyFor(secret.toByteArray(StandardCharsets.UTF_8))

    fun generateToken(email: String, role: String): String {
        return Jwts.builder()
            .setSubject(email)
            .claim("role", role)
            .claim("type", "access")
            .setIssuedAt(Date())
            .setExpiration(Date(System.currentTimeMillis() + expirationTime))
            .signWith(secretKey, SignatureAlgorithm.HS256)
            .compact()
    }

    fun generateRefreshToken(email: String): String {
        return Jwts.builder()
            .setSubject(email)
            .claim("type", "refresh")
            .setIssuedAt(Date())
            .setExpiration(Date(System.currentTimeMillis() + refreshExpirationTime))
            .signWith(secretKey, SignatureAlgorithm.HS256)
            .compact()
    }

    fun validateToken(token: String): String? {
        return try {
            val claims = Jwts.parserBuilder().setSigningKey(secretKey).build()
                .parseClaimsJws(token)
                .body
            val type = claims["type"]?.toString()
            if (type == "refresh") {
                null
            } else {
                claims.subject
            }
        } catch (e: Exception) {
            null
        }
    }

    fun validateRefreshToken(token: String): String? {
        return try {
            val claims = Jwts.parserBuilder().setSigningKey(secretKey).build()
                .parseClaimsJws(token)
                .body
            val type = claims["type"]?.toString()
            if (type == "refresh") {
                claims.subject
            } else {
                null
            }
        } catch (e: Exception) {
            null
        }
    }

    fun getRoleFromToken(token: String): String {
        return Jwts.parserBuilder().setSigningKey(secretKey).build()
            .parseClaimsJws(token)
            .body["role"].toString()
    }
}
