import Foundation // Tarih işlemleri veya diğer temel framework'ler için gerekli olabilir

struct Sınav: Identifiable { // Eğer bir liste içinde kullanacaksanız Identifiable protokolünü eklemek iyi bir fikirdir
    let id = UUID() // Her sınav için benzersiz bir kimlik
    var ad: String
    var tarih: String
}
