package com.gym.backend.service

import io.jsonwebtoken.Jwts
import io.jsonwebtoken.SignatureAlgorithm
import io.jsonwebtoken.security.Keys
import org.springframework.stereotype.Service
import java.util.*

@Service
class JwtService {
    private val secretKey = Keys.hmacShaKeyFor("cok-gizli-ve-uzun-bir-anahtar-buraya-gelmeli-32-karakter".toByteArray())
    private val expirationTime = 86400000 // 24 saat (milisaniye)

    fun generateToken(email: String, role: String): String {
        return Jwts.builder()
            .setSubject(email)
            .claim("role", role)
            .setIssuedAt(Date())
            .setExpiration(Date(System.currentTimeMillis() + expirationTime))
            .signWith(secretKey, SignatureAlgorithm.HS256)
            .compact()
    }

    fun validateToken(token: String): String? {
        return try {
            Jwts.parserBuilder().setSigningKey(secretKey).build()
                .parseClaimsJws(token)
                .body.subject
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
