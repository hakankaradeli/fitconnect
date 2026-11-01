package com.gym.backend.config

import org.slf4j.LoggerFactory
import org.springframework.dao.DataAccessException
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.access.AccessDeniedException
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice
import java.sql.SQLException

@RestControllerAdvice
class GlobalExceptionHandler {

    private val logger = LoggerFactory.getLogger(GlobalExceptionHandler::class.java)

    @ExceptionHandler(AccessDeniedException::class)
    fun handleAccessDenied(e: AccessDeniedException): ResponseEntity<Map<String, String>> {
        logger.warn("Yetkisiz erişim: {}", e.message)
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
            .body(mapOf("error" to "Bu işlem için yetkiniz bulunmamaktadır."))
    }

    @ExceptionHandler(DataAccessException::class, SQLException::class)
    fun handleDatabaseException(e: Exception): ResponseEntity<Map<String, String>> {
        logger.error("Veritabanı / SQL hatası yakalandı: {}", e.message, e)
        return ResponseEntity.badRequest()
            .body(mapOf("error" to "İşlem sırasında bir veritabanı hatası oluştu."))
    }

    @ExceptionHandler(Exception::class)
    fun handleException(e: Exception): ResponseEntity<Map<String, String>> {
        logger.error("Sistem hatası: {}", e.message, e)
        val safeMessage = sanitizeMessage(e)
        return ResponseEntity.badRequest().body(mapOf("error" to safeMessage))
    }

    companion object {
        private val SENSITIVE_PATTERNS = listOf(
            "sql", "org.hibernate", "org.postgresql", "constraint", "syntax error",
            "table", "column", "foreign key", "primary key", "violation", "deadlock",
            "nullpointer", "stacktrace", "exception in thread", "org.springframework",
            "datasource", "jdbc", "hikaripool", "connection refused", "psqlexception"
        )

        fun sanitizeMessage(e: Throwable?): String {
            if (e == null) return "Bir hata oluştu."
            val msg = e.message?.trim() ?: return "Bir hata oluştu."
            if (msg.isBlank()) return "Bir hata oluştu."

            val lower = msg.lowercase()
            for (pattern in SENSITIVE_PATTERNS) {
                if (lower.contains(pattern)) {
                    return "İşlem gerçekleştirilirken bir sistem hatası oluştu."
                }
            }

            if (msg.length > 200 || msg.contains("Exception:") || msg.contains("at com.")) {
                return "İşlem sırasında beklenmeyen bir hata oluştu."
            }

            return msg
        }
    }
}
