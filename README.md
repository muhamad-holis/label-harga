# Label Harga

Aplikasi Flutter untuk membuat & mencetak label harga barang (nama + harga)
lewat printer Bluetooth thermal (58/80mm), untuk ditempel di rak produk.

## Isi paket ini

File di ZIP ini adalah **kode sumber `lib/` + `pubspec.yaml`**, belum termasuk
folder `android/`, `ios/`, dll (dibuat otomatis oleh `flutter create`).

## Cara setup di Termux

```bash
# 1. Buat project Flutter kosong
flutter create label_harga
cd label_harga

# 2. Timpa lib/ dan pubspec.yaml dengan isi ZIP ini
#    (misal ZIP sudah di-unzip ke ~/label_harga_src)
rm -rf lib
cp -r ~/label_harga_src/lib ./lib
cp ~/label_harga_src/pubspec.yaml ./pubspec.yaml

# 3. Ambil dependency
flutter pub get

# 4. Generate kode Drift (database)
dart run build_runner build --delete-conflicting-outputs

# 5. Tambahkan izin Bluetooth di android/app/src/main/AndroidManifest.xml
#    (lihat bagian "Izin Android" di bawah)

# 6. Jalankan / build APK
flutter run
# atau
flutter build apk --release
```

## Izin Android

Tambahkan di dalam tag `<manifest>` pada
`android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

## Alur pemakaian

1. Pairing printer thermal lewat Pengaturan Bluetooth Android (sekali saja).
2. Buka app → ketuk ikon printer → pilih printer dari daftar → tersambung.
3. Tambah barang (nama + harga) lewat tombol `+`.
4. Centang barang yang mau dicetak, atur jumlah label per barang.
5. Ketuk "Cetak" — label langsung tercetak, siap digunting & ditempel.

## Fitur (v2)

- Satu barang bisa punya beberapa satuan & harga sekaligus (Dus/Pack/Pcs,
  atau satuan bebas apa saja) — bebas jumlahnya, tidak wajib 3.
- Pencarian nama barang di halaman utama.
- Preview label (tampilan mirip hasil cetak) sebelum benar-benar dicetak.
- Riwayat cetak, lengkap dengan tombol "cetak ulang" per entri.

## Catatan

- **PENTING**: karena struktur database berubah (harga per satuan, bukan
  satu harga per barang), kalau HP sudah pernah pasang APK versi
  sebelumnya, **uninstall dulu APK lama** sebelum install yang baru ini —
  supaya tidak crash karena skema database lama tidak cocok.
- Default kertas diset **58mm** di `print_preview_screen.dart` &
  `history_screen.dart` (`paperSizeMm: 58`). Ganti ke `80` kalau printer
  memakai roll 80mm.
- Data barang tersimpan lokal (SQLite via Drift) — tidak perlu koneksi
  internet.
- Struktur & stack sengaja disamakan dengan KasirkuPro (Flutter + Riverpod +
  Drift) supaya mudah dipelihara/di-merge kalau nanti mau digabung.
