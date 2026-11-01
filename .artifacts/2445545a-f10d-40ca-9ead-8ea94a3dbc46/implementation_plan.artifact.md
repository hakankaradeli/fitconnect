# Backend Veritabanı Altyapısı Kurulum Planı

Bu plan, FitConnect uygulaması için PostgreSQL tabanlı veritabanı altyapısını sıfırdan kurmayı ve temel fitness modellerini (Egzersiz, Antrenman vb.) eklemeyi amaçlar.

## Proposed Changes

### 1. Altyapı (Infrastructure)

Kolay kurulum ve taşınabilirlik için Docker Compose kullanılacaktır.

#### [NEW] [docker-compose.yml](file:///D:/Projeler/ai_Flutter/fitconnect/backend/docker-compose.yml)
- PostgreSQL 15 imajı.
- `hkfitconnect_db` veritabanının otomatik oluşturulması.
- Kalıcı veri saklama (volumes).

### 2. Veri Modelleri (Domain Models)

Mevcut modellere ek olarak eksik olan temel fitness tabloları eklenecektir.

#### [NEW] [Exercise.kt](file:///D:/Projeler/ai_Flutter/fitconnect/backend/src/main/kotlin/com/gym/backend/model/Exercise.kt)
- Egzersiz adı, kategorisi (Göğüs, Sırt vb.), açıklama ve varsa video linki.

#### [NEW] [Workout.kt](file:///D:/Projeler/ai_Flutter/fitconnect/backend/src/main/kotlin/com/gym/backend/model/Workout.kt)
- Antrenman programı başlığı, açıklama ve bir dizi egzersiz (WorkoutExercise ilişkisi ile).

#### [NEW] [WorkoutExercise.kt](file:///D:/Projeler/ai_Flutter/fitconnect/backend/src/main/kotlin/com/gym/backend/model/WorkoutExercise.kt)
- Antrenmandaki egzersizin set, tekrar ve dinlenme süresi bilgileri.

### 3. Veri Erişimi ve Başlatma (Repositories & Seeding)

#### [NEW] [DataSeeder.kt](file:///D:/Projeler/ai_Flutter/fitconnect/backend/src/main/kotlin/com/gym/backend/config/DataSeeder.kt)
- Uygulama başladığında veritabanı boşsa; bir Admin, bir Gym ve temel egzersiz listesini (Push-up, Squat vb.) ekleyen bileşen.

## Verification Plan

### Automated Tests
- `./gradlew test` komutu ile JPA entegrasyon testlerinin çalıştırılması.

### Manual Verification
- Docker container'ın başlatılması (`docker-compose up -d`).
- `pgAdmin` veya IDE veritabanı gezgini ile tabloların ve `DataSeeder` tarafından eklenen verilerin kontrol edilmesi.
- Spring Boot uygulamasının loglarından Hibernate SQL çıktılarının izlenmesi.
