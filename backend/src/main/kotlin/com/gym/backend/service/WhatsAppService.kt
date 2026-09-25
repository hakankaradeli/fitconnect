package com.gym.backend.service

import org.springframework.stereotype.Service

@Service
class WhatsAppService {
    fun sendMessage(phone: String?, message: String) {
        if (phone == null) {
            println("WhatsApp Gönderilemedi: Telefon numarası eksik.")
            return
        }
        // Burada gerçek bir WhatsApp API (Twilio, MessageBird vb.) entegrasyonu yapılabilir.
        println("WhatsApp Mesajı Gönderildi ($phone): $message")
    }
}
