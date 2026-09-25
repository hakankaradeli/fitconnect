package com.gym.backend.config

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity
import org.springframework.security.config.annotation.web.builders.HttpSecurity
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity
import org.springframework.security.config.http.SessionCreationPolicy
import org.springframework.security.web.SecurityFilterChain
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter
import org.springframework.web.cors.CorsConfiguration
import org.springframework.web.cors.UrlBasedCorsConfigurationSource
import org.springframework.web.filter.CorsFilter

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
class SecurityConfig(private val jwtFilter: JwtAuthenticationFilter) {

    @Bean
    fun filterChain(http: HttpSecurity): SecurityFilterChain {
        http.csrf { it.disable() }
            .cors { } // CORS'u varsayılan yapılandırma ile etkinleştir
            .authorizeHttpRequests { auth ->
                auth.requestMatchers("/api/auth/**").permitAll() 
                    .anyRequest().authenticated() 
            }
            .sessionManagement { it.sessionCreationPolicy(SessionCreationPolicy.STATELESS) }
            .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter::class.java)
        
        return http.build()
    }

    @Bean
    fun corsConfigurationSource(): UrlBasedCorsConfigurationSource {
        val source = UrlBasedCorsConfigurationSource()
        val config = CorsConfiguration()
        
        // Geliştirme aşamasında tüm kökenlere, başlıklara ve metodlara izin veriyoruz.
        config.allowCredentials = true
        config.addAllowedOriginPattern("*") // Tüm adreslere izin ver (Flutter Web dahil)
        config.addAllowedHeader("*") // Tüm başlıklara izin ver
        config.addAllowedMethod("*") // Tüm HTTP metodlarına (GET, POST, PUT, DELETE vb.) izin ver
        
        source.registerCorsConfiguration("/**", config)
        return source
    }
}
