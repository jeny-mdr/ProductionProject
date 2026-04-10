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

// Chat REST
const String kChatRoomsUrl = '$kBaseUrl/api/chat/rooms/';
String kMarkReadUrl(int roomId) => '$kBaseUrl/api/chat/rooms/$roomId/read/';

// Chat WebSocket
String kChatWsUrl(String otherUserId, String token) =>
    '$kWsBaseUrl/ws/chat/$otherUserId/?token=$token';

// Blockchain
const String kSavePrescriptionUrl = '$kBaseUrl/api/blockchain/prescriptions/save/';
const String kMyPrescriptionsUrl   = '$kBaseUrl/api/blockchain/prescriptions/mine/';

