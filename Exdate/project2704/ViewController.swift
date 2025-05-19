import UIKit
import UserNotifications

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UNUserNotificationCenterDelegate {

    @IBOutlet weak var sinavlarimLabel: UILabel!
    @IBOutlet weak var tarihlerLabel: UILabel!
    @IBOutlet weak var sinavlarTableView: UITableView!
    @IBOutlet weak var Alarm: UIImageView!
    @IBOutlet weak var motivasyonLabel: UILabel!  // <- Storyboard'a bağla

    var sinavlar: [(ad: String, tarih: String, dakikaOnce: Int)] = []
    let sinavlarUserDefaultsKey = "kaydedilenSinavlarListesi"
    var aktifSinavAdi: String = ""
    var timer: Timer?
    
    // MOTİVASYON
    let motivasyonMesajlari = [
        "Bugün harika bir gün! ✨👑",
        "Kendine inan, başarabilirsin!💪",
        "Azim başarı getirir!🔥",
        "Bir adım at, gerisi gelir.🎯 🎯",
        "Her yeni gün bir fırsattır.🔥👑",
        "Yola çıkmak, yarının başarısını başlatır! 🌟",
        "Başarı, cesaretin ödülüdür. 💪✨",
        "Hayallerinin peşinden git! 🚀",
        "Küçük adımlar büyük farklar yaratır. 🌱.",
        "Bugün, kendine bir şans ver! 🌟"
    ]
    var motivasyonIndex = 0
    var motivasyonTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        sinavlarimLabel.text = "Sınavlarım"
        tarihlerLabel.text = "Hatırlatıcı"
        sinavlarimLabel.numberOfLines = 0
        tarihlerLabel.numberOfLines = 0

        sinavlarTableView.delegate = self
        sinavlarTableView.dataSource = self
        sinavlarTableView.tableFooterView = UIView()

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Bildirim izni verildi.")
                UNUserNotificationCenter.current().delegate = self
            } else {
                print("Bildirim izni reddedildi: \(error?.localizedDescription ?? "bilinmeyen hata")")
            }
        }

        loadSinavlar()
        startReminderTimer()
        startMotivationTimer() // <-- Motivasyon mesajlarını başlat
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadSinavlar()
        sinavlarTableView.reloadData()
    }

    func startReminderTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkUpcomingExams()
        }
    }

    func startMotivationTimer() {
        updateMotivationMessage()
        motivasyonTimer = Timer.scheduledTimer(withTimeInterval: 6, repeats: true) { [weak self] _ in
            self?.updateMotivationMessage()
        }
    }

    func updateMotivationMessage() {
        UIView.transition(with: motivasyonLabel,
                          duration: 0.5, // Geçişin süresi (saniye)
                          options: .transitionCrossDissolve, // Geçiş stili (fade-in/fade-out)
                          animations: {
                            self.motivasyonLabel.text = self.motivasyonMesajlari[self.motivasyonIndex]
                            self.motivasyonIndex = (self.motivasyonIndex + 1) % self.motivasyonMesajlari.count
                          }, completion: nil)
    }

    func checkUpcomingExams() {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"

        for sinav in sinavlar {
            if let sinavTarihi = formatter.date(from: sinav.tarih) {
                let hatirlatmaZamani = Calendar.current.date(byAdding: .minute, value: -sinav.dakikaOnce, to: sinavTarihi)!
                let interval = hatirlatmaZamani.timeIntervalSince(now)

                if interval >= 0 && interval < 60 {
                    showAlertForUpcomingExam(sinav.ad)
                }
            }
        }
    }

    func showAlertForUpcomingExam(_ examName: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "⏰ Uyarı", message: "\(examName) sınavın yaklaşıyor!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Tamam", style: .default))
            self.present(alert, animated: true)
        }
    }

    @IBAction func yeniSinavEkleButtonTapped(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Yeni Sınav Ekle", message: "Sınav adı ve tarihini giriniz.", preferredStyle: .alert)

        alertController.addTextField { $0.placeholder = "Sınav Adı" }

        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        datePicker.minimumDate = Date()
        datePicker.preferredDatePickerStyle = .wheels
        alertController.view.addSubview(datePicker)

        datePicker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            datePicker.leadingAnchor.constraint(equalTo: alertController.view.leadingAnchor),
            datePicker.trailingAnchor.constraint(equalTo: alertController.view.trailingAnchor),
            datePicker.topAnchor.constraint(equalTo: alertController.view.topAnchor, constant: 100),
            datePicker.bottomAnchor.constraint(equalTo: alertController.view.bottomAnchor, constant: -50)
        ])

        let addAction = UIAlertAction(title: "Ekle", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let sinavAdi = alertController.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !sinavAdi.isEmpty {
                self.showNotificationTimeAlert(for: datePicker.date, sinavAdi: sinavAdi)
            } else {
                self.presentAlert(title: "Uyarı", message: "Lütfen sınav adı ve tarihi boş bırakmayınız.")
            }
        }

        alertController.addAction(addAction)
        alertController.addAction(UIAlertAction(title: "İptal", style: .cancel))
        present(alertController, animated: true)
    }

    func showNotificationTimeAlert(for date: Date, sinavAdi: String) {
        let alertController = UIAlertController(title: "Bildirim Zamanı Seç", message: "Sınavdan ne kadar önce hatırlatılsın?", preferredStyle: .alert)

        let times: [Int: String] = [
            5: "5 dakika önce",
            15: "15 dakika önce",
            30: "30 dakika önce",
            60: "1 saat önce",
            720: "12 saat önce",
            1440: "1 gün önce"
        ]
        
        let sortedTimes = times.sorted { $0.key < $1.key }

        for (time, title) in sortedTimes {
            alertController.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                guard let self = self else { return }

                self.aktifSinavAdi = sinavAdi
                self.scheduleNotification(for: date, minutesBefore: time)

                let formatter = DateFormatter()
                formatter.dateFormat = "dd.MM.yyyy HH:mm"
                self.sinavlar.append((ad: sinavAdi, tarih: formatter.string(from: date), dakikaOnce: time))

                self.saveSinavlar()
                self.sinavlarTableView.reloadData()
            })
        }

        alertController.addAction(UIAlertAction(title: "İptal", style: .cancel))
        present(alertController, animated: true)
    }

    func scheduleNotification(for date: Date, minutesBefore: Int) {
        let content = UNMutableNotificationContent()
        content.title = "⏰ Dikkat!"
        content.body = "\(aktifSinavAdi) sınavın yaklaşıyor!\nBaşaracağından şüphem yok! 💪"
        content.sound = .default

        let triggerDate = Calendar.current.date(byAdding: .minute, value: -minutesBefore, to: date)!
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Bildirim hatası: \(error.localizedDescription)")
            }
        }
    }

    @IBAction func sinavlarıTemizleButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Tüm Sınavları Sil", message: "Emin misiniz?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Sil", style: .destructive) { [weak self] _ in
            self?.sinavlar.removeAll()
            UserDefaults.standard.removeObject(forKey: self?.sinavlarUserDefaultsKey ?? "")
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            self?.sinavlarTableView.reloadData()
        })
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        present(alert, animated: true)
    }

    func saveSinavlar() {
        let saved = sinavlar.map { "\($0.ad)|\($0.tarih)|\($0.dakikaOnce)" }
        UserDefaults.standard.set(saved, forKey: sinavlarUserDefaultsKey)
    }

    func loadSinavlar() {
        if let saved = UserDefaults.standard.array(forKey: sinavlarUserDefaultsKey) as? [String] {
            self.sinavlar = saved.compactMap {
                let parts = $0.components(separatedBy: "|")
                guard parts.count == 3, let dakika = Int(parts[2]) else { return nil }
                return (parts[0], parts[1], dakika)
            }
        }
    }

    func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }

    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sinavlar.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SinavCell", for: indexPath)
        let sinav = sinavlar[indexPath.row]

        cell.textLabel?.text = sinav.ad

        let zamanMetni: String
        switch sinav.dakikaOnce {
        case 1440:
            zamanMetni = "1 gün önce"
        case 720:
            zamanMetni = "12 saat önce"
        case 60:
            zamanMetni = "1 saat önce"
        default:
            zamanMetni = "\(sinav.dakikaOnce) dk önce"
        }
        cell.detailTextLabel?.text = "\(sinav.tarih) — \(zamanMetni)"

        let alarmImageView = UIImageView(image: UIImage(systemName: "bell"))
        alarmImageView.frame = CGRect(x: cell.frame.width - 30, y: (cell.frame.height - 30) / 2, width: 30, height: 30)
        cell.addSubview(alarmImageView)

        return cell
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Veriyi modelden sil
            sinavlar.remove(at: indexPath.row)
            
            // Güncellenmiş veriyi UserDefaults'a kaydet
            saveSinavlar()
            
            // TableView'dan ilgili satırı sil
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sinav = sinavlar[indexPath.row]
        
        // Uyarı penceresini oluştur
        let alert = UIAlertController(title: "Düzenle", message: "Sınav adını düzenleyin.", preferredStyle: .alert)
        
        // TextField ekle (Sınav adı için)
        alert.addTextField { textField in
            textField.text = sinav.ad
            textField.placeholder = "Sınav Adı"
        }
        
        // Kaydetme işlemi için bir buton ekliyoruz
        let saveAction = UIAlertAction(title: "Kaydet", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let updatedSinavAdi = alert.textFields?.first?.text ?? ""
            
            // Eğer yeni bir sınav adı girildiyse, güncelleme işlemi yapılır.
            if !updatedSinavAdi.isEmpty {
                self.sinavlar[indexPath.row].ad = updatedSinavAdi
                self.saveSinavlar() // Yeni sınav adını kaydet
                self.sinavlarTableView.reloadData() // Table'ı güncelle
            }
        }
        
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel)) // İptal tuşu ekliyoruz
        
        // Alert'i göster
        self.present(alert, animated: true)
    }


}
