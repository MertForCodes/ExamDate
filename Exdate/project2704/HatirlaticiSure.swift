
// HatirlaticiSure.swift (veya başka bir uygun Swift dosyası içinde tanımlayabilirsiniz)

import Foundation

enum HatirlaticiSure: String, CaseIterable {
    case sinavAninda = "Sınav Anında"
    case onBesDakikaOnce = "15 Dakika Önce"
    case otuzDakikaOnce = "30 Dakika Önce"
    case birSaatOnce = "1 Saat Önce"
    case birGunOnce = "1 Gün Önce"

    // Her bir case için saniye cinsinden süreyi döndüren bir metot
    func timeInterval() -> TimeInterval {
        switch self {
        case .sinavAninda:
            return 0
        case .onBesDakikaOnce:
            return -15 * 60 // 15 dakika geriye
        case .otuzDakikaOnce:
            return -30 * 60 // 30 dakika geriye
        case .birSaatOnce:
            return -60 * 60 // 1 saat geriye
        case .birGunOnce:
            return -24 * 60 * 60 // 1 gün geriye
        }
    }
}
