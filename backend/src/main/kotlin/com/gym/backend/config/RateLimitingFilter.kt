package com.gym.backend.config

import com.gym.backend.service.RateLimiterService
import jakarta.servlet.FilterChain
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.slf4j.LoggerFactory
import org.springframework.http.HttpStatus
import org.springframework.http.MediaType
import org.springframework.stereotype.Component
import org.springframework.web.filter.OncePerRequestFilter

@Component
class RateLimitingFilter(
    private val rateLimiterService: RateLimiterService
) : OncePerRequestFilter() {

    private val rateLimiterLogger = LoggerFactory.getLogger(RateLimitingFilter::class.java)

    override fun doFilterInternal(
        request: HttpServletRequest,
        response: HttpServletResponse,
        filterChain: FilterChain
    ) {
        if (request.method.equals("OPTIONS", ignoreCase = true)) {
            filterChain.doFilter(request, response)
            return
        }

        val path = request.requestURI

        if (path.endsWith("/api/auth/login") && request.method.equals("POST", ignoreCase = true)) {
            val clientIp = getClientIp(request)
            val probe = rateLimiterService.tryConsumeLogin(clientIp)

            if (!probe.isConsumed) {
                val retryAfterSeconds = (probe.nanosToWaitForRefill / 1_000_000_000L).coerceAtLeast(1)
                rateLimiterLogger.warn("Giriş denemesi rate limit aşıldı! Engellenen IP: ${maskIp(clientIp)}")

                response.status = HttpStatus.TOO_MANY_REQUESTS.value()
                response.contentType = "${MediaType.APPLICATION_JSON_VALUE};charset=UTF-8"
                response.setHeader("Retry-After", retryAfterSeconds.toString())
                response.writer.write(
                    """{"error":"Çok fazla hatalı veya ardışık giriş denemesi yapıldı. Lütfen $retryAfterSeconds saniye sonra tekrar deneyiniz."}"""
                )
                return
            }

            response.setHeader("X-Rate-Limit-Remaining", probe.remainingTokens.toString())
        } else if (path.endsWith("/api/auth/register") && request.method.equals("POST", ignoreCase = true)) {
            val clientIp = getClientIp(request)
            val probe = rateLimiterService.tryConsumeRegister(clientIp)

            if (!probe.isConsumed) {
                val retryAfterSeconds = (probe.nanosToWaitForRefill / 1_000_000_000L).coerceAtLeast(1)
                rateLimiterLogger.warn("Kayıt olma rate limit aşıldı! Engellenen IP: ${maskIp(clientIp)}")

                response.status = HttpStatus.TOO_MANY_REQUESTS.value()
                response.contentType = "${MediaType.APPLICATION_JSON_VALUE};charset=UTF-8"
                response.setHeader("Retry-After", retryAfterSeconds.toString())
                response.writer.write(
                    """{"error":"Çok fazla kayıt denemesi yapıldı. Lütfen $retryAfterSeconds saniye sonra tekrar deneyiniz."}"""
                )
                return
            }

            response.setHeader("X-Rate-Limit-Remaining", probe.remainingTokens.toString())
        }

        filterChain.doFilter(request, response)
    }

    private fun getClientIp(request: HttpServletRequest): String {
        val xForwardedFor = request.getHeader("X-Forwarded-For")
        if (!xForwardedFor.isNullOrBlank()) {
            return xForwardedFor.split(",").first().trim()
        }
        val realIp = request.getHeader("X-Real-IP")
        if (!realIp.isNullOrBlank()) {
            return realIp.trim()
        }
        return request.remoteAddr ?: "unknown"
    }

    private fun maskIp(ip: String): String {
        val parts = ip.split(".")
        return if (parts.size == 4) {
            "${parts[0]}.${parts[1]}.***.***"
        } else {
            "***"
        }
    }
}
