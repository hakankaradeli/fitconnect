package com.gym.backend.config

import com.gym.backend.service.JwtService
import com.gym.backend.service.DelegationService
import jakarta.servlet.FilterChain
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.authority.SimpleGrantedAuthority
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.stereotype.Component
import org.springframework.web.filter.OncePerRequestFilter

@Component
class JwtAuthenticationFilter(
    private val jwtService: JwtService,
    private val delegationService: DelegationService
) : OncePerRequestFilter() {

    override fun doFilterInternal(request: HttpServletRequest, response: HttpServletResponse, filterChain: FilterChain) {
        try {
            val authHeader = request.getHeader("Authorization")

            if (authHeader != null && authHeader.startsWith("Bearer ")) {
                val token = authHeader.substring(7)
                val email = jwtService.validateToken(token)

                if (email != null && SecurityContextHolder.getContext().authentication == null) {
                    val role = jwtService.getRoleFromToken(token).uppercase()
                    
                    val authorities = mutableListOf(
                        SimpleGrantedAuthority("ROLE_$role"),
                        SimpleGrantedAuthority(role)
                    )
                    
                    try {
                        val tempPermissions = delegationService.getActivePermissions(email)
                        tempPermissions.forEach { perm ->
                            authorities.add(SimpleGrantedAuthority("PERM_${perm.name}"))
                            if (perm.name == "FULL_ADMIN_ACCESS") {
                                authorities.add(SimpleGrantedAuthority("ROLE_ADMIN"))
                            }
                        }
                    } catch (e: Exception) {
                    }
                    
                    val authToken = UsernamePasswordAuthenticationToken(email, null, authorities)
                    SecurityContextHolder.getContext().authentication = authToken
                }
            }
        } catch (e: Exception) {
            // Ignore token parsing exceptions on unauthenticated endpoints
        }
        filterChain.doFilter(request, response)
    }
}
