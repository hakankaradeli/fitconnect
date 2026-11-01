package com.gym.backend.service

import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service

@Service
class WhatsAppService {

    private val logger = LoggerFactory.getLogger(WhatsAppService::class.java)

    private fun maskPhone(phone: String): String {
        return if (phone.length > 4) {
            "***" + phone.takeLast(4)
        } else {
            "***"
        }
    }

    fun sendMessage(phone: String?, message: String) {
        if (phone.isNullOrBlank()) {
            logger.warn("WhatsApp gönderilemedi: Telefon numarası eksik.")
            return
        }
        // Burada gerçek bir WhatsApp API (Twilio, MessageBird vb.) entegrasyonu yapılabilir.
        logger.info("WhatsApp mesajı iletildi (Alıcı: {})", maskPhone(phone))
    }
}
