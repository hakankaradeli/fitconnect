package com.gym.backend.repository

import com.gym.backend.model.Booking
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository
import java.time.LocalDateTime

@Repository
interface BookingRepository : JpaRepository<Booking, Long> {
    
    // Belirli bir salonda, belirli bir saatte kaç aktif randevu var?
    @Query("SELECT COUNT(b) FROM Booking b WHERE b.gym.id = :gymId AND b.startTime = :startTime AND b.status != 'CANCELLED'")
    fun countActiveBookings(gymId: Long, startTime: LocalDateTime): Int

    // Üyenin o gün başka randevusu var mı? (Opsiyonel kontrol)
    fun findByMemberIdAndStartTime(memberId: Long, startTime: LocalDateTime): List<Booking>

    fun countByGymId(gymId: Long): Int
    fun countByGymIdAndStatus(gymId: Long, status: String): Int
    fun findAllByGymIdAndStatusOrderByStartTimeAsc(gymId: Long, status: String): List<Booking>

    // Salondaki tüm eğitmenlerin belirli bir tarih aralığındaki aktif randevuları
    @Query("SELECT b FROM Booking b WHERE b.gym.id = :gymId AND b.startTime BETWEEN :start AND :end AND b.status != 'CANCELLED' ORDER BY b.startTime ASC")
    fun findAllActiveByGymIdAndStartTimeBetween(
        @org.springframework.data.repository.query.Param("gymId") gymId: Long,
        @org.springframework.data.repository.query.Param("start") start: LocalDateTime,
        @org.springframework.data.repository.query.Param("end") end: LocalDateTime
    ): List<Booking>

    // Eğitmenin belirli bir tarih aralığındaki tüm randevularını getir
    @Query("SELECT b FROM Booking b WHERE b.trainer.id = :trainerId AND b.startTime BETWEEN :start AND :end AND b.status != 'CANCELLED' ORDER BY b.startTime ASC")
    fun findAllActiveByTrainerIdAndStartTimeBetween(
        @org.springframework.data.repository.query.Param("trainerId") trainerId: Long,
        @org.springframework.data.repository.query.Param("start") start: LocalDateTime,
        @org.springframework.data.repository.query.Param("end") end: LocalDateTime
    ): List<Booking>

    @Query("SELECT b FROM Booking b WHERE b.member.id = :memberId AND b.status != 'CANCELLED' ORDER BY b.startTime ASC")
    fun findAllActiveByMemberId(@org.springframework.data.repository.query.Param("memberId") memberId: Long): List<Booking>

    fun findAllByMemberIdAndStatus(memberId: Long, status: String): List<Booking>
    fun findAllByTrainerIdAndStatus(trainerId: Long, status: String): List<Booking>
    
    @Query("SELECT b FROM Booking b WHERE b.member.id = :memberId AND b.startTime > :startTime AND b.status != 'CANCELLED'")
    fun findAllActiveByMemberIdAndStartTimeAfter(
        @org.springframework.data.repository.query.Param("memberId") memberId: Long,
        @org.springframework.data.repository.query.Param("startTime") startTime: LocalDateTime
    ): List<Booking>

    @Query("SELECT b FROM Booking b WHERE b.trainer.id = :trainerId AND b.startTime > :startTime AND b.status != 'CANCELLED'")
    fun findAllActiveByTrainerIdAndStartTimeAfter(
        @org.springframework.data.repository.query.Param("trainerId") trainerId: Long,
        @org.springframework.data.repository.query.Param("startTime") startTime: LocalDateTime
    ): List<Booking>

    @Query("SELECT b FROM Booking b WHERE b.trainer.id = :trainerId AND b.status = 'COMPLETED' AND b.startTime >= :since ORDER BY b.startTime DESC")
    fun findLatestCompletedSessions(
        @org.springframework.data.repository.query.Param("trainerId") trainerId: Long,
        @org.springframework.data.repository.query.Param("since") since: LocalDateTime
    ): List<Booking>

    @Query("""
        SELECT COUNT(b) FROM Booking b 
        WHERE b.member.id = :memberId 
        AND b.status = 'CANCELLED' 
        AND (EXTRACT(HOUR FROM b.startTime) IN (7, 8, 9, 10, 18, 19, 20, 21))
    """)
    fun countMemberPeakCancellations(@org.springframework.data.repository.query.Param("memberId") memberId: Long): Int

    @Query("SELECT b FROM Booking b WHERE b.gym.id = :gymId AND (b.status = 'CANCELLED' OR b.status = 'NO_SHOW' OR b.status = 'PENDING_ADMIN_APPROVAL') AND b.startTime BETWEEN :start AND :end ORDER BY b.startTime DESC")
    fun findDailyUnperformedBookings(
        @org.springframework.data.repository.query.Param("gymId") gymId: Long,
        @org.springframework.data.repository.query.Param("start") start: LocalDateTime,
        @org.springframework.data.repository.query.Param("end") end: LocalDateTime
    ): List<Booking>

    @Query(value = """
        SELECT u.full_name as name, COUNT(b.id) as count 
        FROM bookings b 
        JOIN users u ON b.cancelled_by_id = u.id 
        WHERE u.role = 'MEMBER' AND b.status = 'CANCELLED'
        GROUP BY u.id, u.full_name 
        ORDER BY count DESC 
        LIMIT 5
    """, nativeQuery = true)
    fun findTopCancelledMembers(): List<Map<String, Any>>

    @Query(value = """
        SELECT t.full_name as name, COUNT(b.id) as count 
        FROM bookings b 
        JOIN users t ON b.trainer_id = t.id 
        WHERE b.status = 'CANCELLED' AND b.cancelled_by_id != t.id
        GROUP BY t.id, t.full_name 
        ORDER BY count DESC 
        LIMIT 5
    """, nativeQuery = true)
    fun findTopCancelledTrainersByOthers(): List<Map<String, Any>>

    @Query(value = """
        SELECT t.full_name as name, COUNT(b.id) as count 
        FROM bookings b 
        JOIN users t ON b.trainer_id = t.id 
        WHERE b.status = 'CANCELLED' AND b.cancelled_by_id = t.id
        GROUP BY t.id, t.full_name 
        ORDER BY count DESC 
        LIMIT 5
    """, nativeQuery = true)
    fun findTopCancellingTrainers(): List<Map<String, Any>>
}
