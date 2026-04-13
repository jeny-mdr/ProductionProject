// Android Emulator
const String kBaseUrl   = 'http://192.168.101.12:8000';
const String kWsBaseUrl = 'ws://192.168.101.12:8000';

// Auth
const String kRegisterUrl = '$kBaseUrl/api/users/register/';
const String kLoginUrl    = '$kBaseUrl/api/users/login/';
const String kProfileUrl  = '$kBaseUrl/api/users/profile/';
const String kDoctorsUrl  = '$kBaseUrl/api/users/doctors/';

// AI
const String kRecommendUrl = '$kBaseUrl/api/ai/recommend/';
const String kSuggestUrl = '$kBaseUrl/api/ai/suggest/';
// Chat REST
const String kChatRoomsUrl = '$kBaseUrl/api/chat/rooms/';
String kMarkReadUrl(int roomId) => '$kBaseUrl/api/chat/rooms/$roomId/read/';
const String kChatUploadUrl = '$kBaseUrl/api/chat/upload/';

// Chat WebSocket
String kChatWsUrl(String otherUserId, String token) =>
    '$kWsBaseUrl/ws/chat/$otherUserId/?token=$token';

// Blockchain
const String kSavePrescriptionUrl = '$kBaseUrl/api/blockchain/prescriptions/save/';
const String kMyPrescriptionsUrl   = '$kBaseUrl/api/blockchain/prescriptions/mine/';

// Appointments
const String kBookAppointmentUrl = '$kBaseUrl/api/appointments/book/';
const String kMyAppointmentsUrl  = '$kBaseUrl/api/appointments/mine/';
String kUpdateAppointmentUrl(int id) => '$kBaseUrl/api/appointments/$id/update/';

const String kHospitalsUrl  = '$kBaseUrl/api/hospitals/nearby/';
const String kPharmaciesUrl = '$kBaseUrl/api/hospitals/pharmacies/';