package com.gym.backend.service

import io.github.bucket4j.Bandwidth
import io.github.bucket4j.Bucket
import io.github.bucket4j.ConsumptionProbe
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service
import java.time.Duration
import java.util.concurrent.ConcurrentHashMap

@Service
class RateLimiterService(
    @Value("\${rate-limit.login.capacity:5}")
    private val loginCapacity: Long = 5,
    @Value("\${rate-limit.login.duration-minutes:1}")
    private val loginDurationMinutes: Long = 1,
    @Value("\${rate-limit.register.capacity:5}")
    private val registerCapacity: Long = 5,
    @Value("\${rate-limit.register.duration-minutes:1}")
    private val registerDurationMinutes: Long = 1
) {
    private val loginBuckets = ConcurrentHashMap<String, Bucket>()
    private val registerBuckets = ConcurrentHashMap<String, Bucket>()

    // Giriş (Login) için Brute-Force koruma bucket'ı
    private fun createLoginBucket(): Bucket {
        val limit = Bandwidth.builder()
            .capacity(loginCapacity)
            .refillIntervally(loginCapacity, Duration.ofMinutes(loginDurationMinutes))
            .build()
        return Bucket.builder().addLimit(limit).build()
    }

    // Kayıt (Register) için spam koruma bucket'ı
    private fun createRegisterBucket(): Bucket {
        val limit = Bandwidth.builder()
            .capacity(registerCapacity)
            .refillIntervally(registerCapacity, Duration.ofMinutes(registerDurationMinutes))
            .build()
        return Bucket.builder().addLimit(limit).build()
    }

    fun tryConsumeLogin(clientIp: String): ConsumptionProbe {
        if (loginBuckets.size > 10_000) {
            loginBuckets.clear()
        }
        val bucket = loginBuckets.computeIfAbsent(clientIp) { createLoginBucket() }
        return bucket.tryConsumeAndReturnRemaining(1)
    }

    fun tryConsumeRegister(clientIp: String): ConsumptionProbe {
        if (registerBuckets.size > 10_000) {
            registerBuckets.clear()
        }
        val bucket = registerBuckets.computeIfAbsent(clientIp) { createRegisterBucket() }
        return bucket.tryConsumeAndReturnRemaining(1)
    }
}
