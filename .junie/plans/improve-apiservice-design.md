---
sessionId: session-261029-203302-1wqk
---

# Requirements

### Overview
ApiService tasarımını iyileştirerek token yönetimini `LoginViewModel`'e taşıyacak, token'ı kalıcı hale getirecek ve View'lardaki doğrudan `ApiService.token` erişimini ortadan kaldıracağız.

### Goals
1. **Token yönetimi** `LoginViewModel` içinde merkezi hale gelsin.
2. **Token kalıcı olsun** — `SharedPreferences` ile saklansın; uygulama yeniden açıldığında kullanıcı otomatik giriş yapmış olsun.
3. **View'larda `ApiService.token = null` kullanımı** tamamen kalsın — yerine `LoginViewModel.logout()` çağrısı yapılsın.
4. **`ApiService` sınıfı korunssun** — statik yapı değişmeden kalsın, sadece token yönetiminin sorumluluğu `LoginViewModel`'e geçsin.

### In Scope
- `LoginViewModel`'e `logout()`, `saveToken()`, `loadToken()` ve `isAuthenticated` eklenmesi
- `SharedPreferences` ile token kalıcılığı
- 4 dashboard dosyasındaki logout kodunun `LoginViewModel.logout()` kullanacak şekilde güncellenmesi
- `main.dart`'ta uygulama başlangıcında token kontrolü ve otomatik giriş akışı
- `login_screen.dart`'ta başarılı giriş sonrası otomatik dashboard yönlendirmesi

### Out of Scope
- `ApiService` sınıfının tamamen kaldırılması veya yeniden tasarımı
- `BaseRepository`'in constructor injection ile token alması
- Repository katmanında yeni sınıflar
- `ApiResult<T>` gibi standart hata tipleri
- Network interceptor eklenmesi

# Technical Design

### Current Implementation
- **`ApiService`** (`lib/services/api_service.dart`): Statik `token` alanı, `baseUrl` ve `getHeaders()` sağlar.
- **`LoginViewModel`** (`lib/view_models/login_view_model.dart`): `login()` ve `register()` metodlarında `ApiService.token = data['token']` ile token'ı doğrudan `ApiService`'e yazar.
- **4 Dashboard** (`admin_dashboard.dart`, `member_dashboard.dart`, `trainer_dashboard.dart`, `super_admin_dashboard.dart`): Logout'ta doğrudan `ApiService.token = null` yapar.
- **`BaseRepository`** (`lib/repositories/base_repository.dart`): `ApiService.getHeaders()` ve `ApiService.baseUrl`'i statik olarak kullanır.
- **`main.dart`**: Tüm ViewModel'leri boş constructor ile oluşturur; token kontrolü yok.

### Key Decisions
1. **Token kalıcılığı**: `SharedPreferences` ile `jwt_token` key'i altında saklanacak.
2. **ApiService korunacak**: Statik yapı değişmeyecek; token okuma/yazma `LoginViewModel` üzerinden yapılacak, `ApiService` sadece `baseUrl` ve `getHeaders()` için kullanılacak.
3. **Logout merkezi**: `LoginViewModel.logout()` token'ı hem hafızadan hem `SharedPreferences`'ten temizleyecek.
4. **Otomatik giriş**: `main.dart`'ta uygulama başlangıcında `SharedPreferences`'ten token kontrolü yapılacak; token varsa dashboard'a yönlendirilecek.

### Proposed Changes

#### 1. LoginViewModel'e Token Yönetimi Ekle
- `saveToken(token)` — token'ı `SharedPreferences`'e ve `ApiService.token`'a yazar
- `loadToken()` — `SharedPreferences`'ten token yükler, `ApiService.token`'a atar
- `clearToken()` — token'ı her iki yerden de temizler
- `logout()` — token'ı temizler, `_userData`'yı sıfırlar
- `bool get isAuthenticated` — `ApiService.token != null` kontrolü

#### 2. Dashboard Logout'ları Güncelle
4 dosyada `ApiService.token = null` yerine `context.read<LoginViewModel>().logout()` kullanılacak:
- `lib/views/admin/admin_dashboard.dart` (satır 455)
- `lib/views/member/member_dashboard.dart` (satır 140, 556)
- `lib/views/trainer/trainer_dashboard.dart` (satır 122, 450)
- `lib/views/super_admin/super_admin_dashboard.dart` (satır 46)

#### 3. main.dart'a Otomatik Giriş Ekle
- Uygulama başlangıcında `SharedPreferences`'ten token kontrolü
- Token varsa `DashboardRouter`'a yönlendirme
- `ThemeViewModel.syncGymBranding()` çağrısı (gerekirse)

#### 4. login_screen.dart Yönlendirmesini Güncelle
- Başarılı giriş sonrası `DashboardRouter` ile doğru dashboard'a yönlendirme
- Şu anki `Navigator.pushReplacement` yerine role-based yönlendirme

### Architecture Diagram

```mermaid
graph LR
    A[View - Dashboard] -->|logout()| B[LoginViewModel]
    B -->|clearToken| C[SharedPreferences]
    B -->|token=null| D[ApiService statik]
    E[main.dart] -->|loadToken| C
    E -->|token varsa| F[DashboardRouter]
    E -->|token yok| G[LoginScreen]
    B -->|saveToken| C
    B -->|token set| D
    D -->|getHeaders| H[BaseRepository]
    H -->|HTTP| I[API]
```

### File Structure
| Dosya | İşlem |
|---|---|
| `lib/view_models/login_view_model.dart` | Token yönetimi metodları eklenecek |
| `lib/main.dart` | Otomatik giriş akışı eklenecek |
| `lib/views/login_screen.dart` | Yönlendirme güncellenecek |
| `lib/views/admin/admin_dashboard.dart` | Logout güncellenecek |
| `lib/views/member/member_dashboard.dart` | Logout güncellenecek (2 yer) |
| `lib/views/trainer/trainer_dashboard.dart` | Logout güncellenecek (2 yer) |
| `lib/views/super_admin/super_admin_dashboard.dart` | Logout güncellenecek |

# Testing

### Key Scenarios
1. **İlk açılış** — Token yoksa `LoginScreen` gösterilmeli
2. **Başarılı giriş** — Token `SharedPreferences`'e kaydedilmeli, dashboard'a yönlendirilmeli
3. **Uygulama yeniden açılış** — Token varsa otomatik dashboard gösterilmeli
4. **Logout** — Token hem hafızadan hem `SharedPreferences`'ten temizlenmeli, `LoginScreen`'e dönülmeli
5. **Register** — Token aynı şekilde kaydedilmeli

### Edge Cases
- `SharedPreferences` bozuk veya erişilemezse hata yakalanmalı
- Token varsa ama geçersizse (401 hatası) — şimdilik scope dışında, mevcut akış devam eder
- `login_screen.dart`'ta `_saveCredentials` ile çakışma olmamalı

# Delivery Steps

### ✓ Step 1: LoginViewModel'e token yönetimi ekle
### ✓ Step 2: Dashboard logout'ları LoginViewModel'e bağla
### ✓ Step 3: main.dart'a otomatik giriş akışı ekle
### ✓ Step 4: login_screen.dart yönlendirmesini güncelle

---

## Additional: Auto Token Refresh

### ✓ Step 5: Otomatik token refresh mekanizması ekle
Access token süresi dolduğunda (30 dk) refresh token ile otomatik yenileme eklenecek.
LoginViewModel'e token kalıcılığı ve logout metodları eklenecek.
- `saveToken(String)` — token'ı SharedPreferences'e ve ApiService.token'a yazar
- `loadToken()` — SharedPreferences'ten token yükler, boş değilse ApiService.token'a atar
- `clearToken()` — token'ı her iki yerden temizler
- `logout()` — clearToken() + _userData sıfırlama + notifyListeners()
- `bool get isAuthenticated` — ApiService.token != null kontrolü
- `login()` ve `register()` metodları `saveToken()` kullanacak şekilde güncellenecek

### ✓ Step 2: Dashboard logout'ları LoginViewModel'e bağla
4 dashboard dosyasındaki `ApiService.token = null` çağrıları `LoginViewModel.logout()` ile değiştirilecek.
- `admin_dashboard.dart` (satır 455): logout butonu
- `member_dashboard.dart` (satır 140): logout butonu, (satır 556): hesap silme sonrası
- `trainer_dashboard.dart` (satır 122): logout butonu, (satır 450): hesap silme sonrası
- `super_admin_dashboard.dart` (satır 46): logout butonu
- Gereksiz `import '../../services/api_service.dart'` import'ları kaldırılacak

### ✓ Step 3: main.dart'a otomatik giriş akışı ekle
Uygulama başlangıcında token kontrolü ve otomatik yönlendirme eklenecek.
- `main()` fonksiyonunda async token kontrolü: SharedPreferences'ten token okunacak
- Token varsa `DashboardRouter`, yoksa `LoginScreen` home olacak
- `LoginViewModel.loadToken()` çağrılarak token ApiService'e de yüklenecek
- `ThemeViewModel` başlatma ile koordinasyon sağlanacak

### ✓ Step 4: login_screen.dart yönlendirmesini güncelle
Başarılı giriş sonrası role-based yönlendirme iyileştirilecek.
- `_login()` metodunda başarılı giriş sonrası `DashboardRouter` kullanılarak doğru dashboard'a yönlendirme
- `LoginViewModel.isAuthenticated` kontrolü ile giriş öncesi/sonrası state yönetimi