ForceQ 1.1 — Apple Silicon Mac, macOS 13 veya üstü.

KULLANIM VE GÜNCELLEME
ForceQ.app uygulamasını açın.
Kalıcı kurulum için eski ForceQ'ten Command-Q ile çıkın. Finder'da yeni ForceQ.app'i Uygulamalar klasörüne taşıyıp önceki kopyayı değiştirin. Gerekirse Dock'taki eski bağlantıyı kaldırıp yenisini ekleyin.
Uygulamayı seçin, Zorla Kapat'a basın ve onaylayın. Kaydedilmemiş değişiklikler kaybolabilir. Finder ve ForceQ listelenmez.

BELLEK ÖLÇÜMÜ
Stats bağlantısı, ağ erişimi veya yönetici parolası gerekmez. proc_pid_rusage üzerinden macOS fiziksel bellek ayak izi ölçülür; sanal bellek boyutu ölçülmez. MB ve GB ondalık birimlerdir.
Ölçüm arka planda yaklaşık üç saniyede bir yapılır. Güncelleme sürüyorsa ikinci bir ölçüm başlatılmaz.
Yardımcı süreçler dahil: Aynı uygulama paketi içindeki çalıştırılabilir dosyalara ait ölçülebilen süreçler toplanır. Paylaşılan veya paket dışında çalışan sistem servisleri dahil değildir. Aynı paketin birden fazla bağımsız örneği varsa belirsiz yardımcılar iki kez sayılmak yerine hariç tutulur.
Bu değerler uygulama bazlı yaklaşık toplamdır. Etkinlik Monitörü'ndeki tek süreç satırıyla veya sistemin toplam bellek kullanımıyla birebir karşılaştırılmamalıdır.
Yardımcı süreçler seçeneğini kapatmak yalnızca ana süreci gösterir.
Okunamayan ölçüm sıfır yerine — gösterilir. Bilinen bazı süreçler okunamadığında eldeki kısmi toplam ≥ ile belirtilir.
Belleğe göre sıralama en çok tüketeni üste getirir. Kapatma onayı seçilen uygulama nesnesini korur; sıralama değişince hedef değişmez.

SÜRÜMLER
1.0: İkonlu liste, arama, onaylı zorla kapatma.
1.1: Canlı bellek ölçümü, yardımcı süreç toplamları, bellek sıralaması, arka plan ölçümü, sürüm etiketi.
Önceki sürüm ve kaynak kodu outputs/releases/v1.0 altında korunmuştur.

GELİŞTİRME
ForceQ.swift arayüz ve kapatma mantığıdır. MemoryMonitor.swift bellek ölçümüdür.
Xcode kurulu Mac'te build.command yeni sürümü üst klasörde ForceQ.app olarak derler. Apple Developer üyeliği gerekmez; yerel ad-hoc imza kullanılır.
test.command; süreç eşleştirme, paket yolu sınırları, birden fazla örnek, okunamayan değerler ve gerçek bellek ayırma testlerini çalıştırır.

DOĞRULAMA
Derleme, uygulama paketi ve yerel imza doğrulandı. Bellek testleri geçti. Canlı uygulamada yardımcı süreç açık/kapalı karşılaştırması, bellek sıralaması, seçim ve onaydan vazgeçme kontrol edildi. Gerçek kullanıcı uygulamalarına test amacıyla zorla kapatma uygulanmadı.

Varsayılan sıralama en yüksek bellek kullanımıdır. Ada göre sıralama menüden seçilebilir. Uygulama adı ForceQ olarak güncellenmiştir; sürüm 1.1 olarak korunmuştur.
