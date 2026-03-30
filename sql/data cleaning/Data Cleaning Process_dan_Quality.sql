-- Duplicate Primary Key
SELECT id, COUNT(*) 
FROM dc_pasien
GROUP BY id
HAVING COUNT(*) > 1;

SELECT id, COUNT(*) 
FROM dc_pegawai
GROUP BY id
HAVING COUNT(*) > 1;

SELECT id, COUNT(*) 
FROM dc_pendaftaran
GROUP BY id
HAVING COUNT(*) > 1;

SELECT id, COUNT(*) 
FROM dc_resep_tebus
GROUP BY id
HAVING COUNT(*) > 1;

SELECT id, COUNT(*) 
FROM dc_resep_tebus_r
GROUP BY id
HAVING COUNT(*) > 1;

SELECT id, COUNT(*) 
FROM dc_resep_tebus_r_detail
GROUP BY id
HAVING COUNT(*) > 1;

SELECT id, COUNT(*) 
FROM dc_nakes
GROUP BY id
HAVING COUNT(*) > 1;

SELECT id, COUNT(*) 
FROM dc_layanan_pendaftaran
GROUP BY id
HAVING COUNT(*) > 1;

SELECT id, COUNT(*) 
FROM dc_golongan_sebab_sakit
GROUP BY id
HAVING COUNT(*) > 1;

SELECT id, COUNT(*) 
FROM dc_diagnosa
GROUP BY id
HAVING COUNT(*) > 1;

SELECT id, COUNT(*) 
FROM cbg_status_klaim
GROUP BY id
HAVING COUNT(*) > 1;

-- Lihat Detail Duplicate
SELECT *
FROM dc_resep_tebus
WHERE id = 114122;

SELECT *
FROM dc_golongan_sebab_sakit
WHERE id = 6;

-- Hapus Duplicate
WITH cte AS (
    SELECT *,
           ROW_NUMBER() OVER(PARTITION BY id ORDER BY id) AS rn
    FROM dc_resep_tebus
)
DELETE FROM dc_resep_tebus
WHERE id IN (
    SELECT id
    FROM cte
    WHERE rn > 1
);

WITH cte AS (
    SELECT *,
           ROW_NUMBER() OVER(PARTITION BY id ORDER BY id) AS rn
    FROM dc_golongan_sebab_sakit
)
DELETE FROM dc_golongan_sebab_sakit
WHERE id IN (
    SELECT id
    FROM cte
    WHERE rn > 1
);

-- Constraint PK Aktif
ALTER TABLE dc_resep_tebus
ADD PRIMARY KEY (id);

ALTER TABLE dc_golongan_sebab_sakit
ADD PRIMARY KEY (id);

-- Foreign Key Integrity
-- 1.1 Nakes Tanpa Pegawai 
SELECT n.*
FROM dc_nakes n
LEFT JOIN dc_pegawai p ON n.id_pegawai = p.id
WHERE p.id IS NULL;

-- 1.2 Pendaftaran Tanpa Pasien 
SELECT p.*
FROM dc_pendaftaran p
LEFT JOIN dc_pasien ps ON p.id_pasien = ps.id
WHERE ps.id IS NULL;

-- 1.3 Layanan Tanpa Pendaftaran 
SELECT l.*
FROM dc_layanan_pendaftaran l
LEFT JOIN dc_pendaftaran p ON l.id_pendaftaran = p.id
WHERE p.id IS NULL;

-- Distribusi Per Layanan
SELECT l.jenis, COUNT(*) AS jumlah_orphan
FROM dc_layanan_pendaftaran AS l
LEFT JOIN dc_pendaftaran AS p ON l.id_pendaftaran = p.id
WHERE p.id IS NULL
GROUP BY l.jenis
ORDER BY jumlah_orphan DESC;

-- Distribusi Per Tanggal Layanan
SELECT DATE(l.waktu) AS tanggal, COUNT(*) AS jumlah_orphan
FROM dc_layanan_pendaftaran AS l
LEFT JOIN dc_pendaftaran AS p ON l.id_pendaftaran = p.id
WHERE p.id IS NULL
GROUP BY DATE(l.waktu)
ORDER BY tanggal;

-- Distribusi Per Dokter
SELECT l.id_dokter, COUNT(*) AS jumlah_orphan
FROM dc_layanan_pendaftaran AS l
LEFT JOIN dc_pendaftaran AS p ON l.id_pendaftaran = p.id
WHERE p.id IS NULL
GROUP BY l.id_dokter
ORDER BY jumlah_orphan DESC;

SELECT 
    l.id_dokter, 
    l.jenis, 
    DATE(l.waktu) AS tanggal,
    COUNT(*) AS jumlah_orphan
FROM dc_layanan_pendaftaran AS l
LEFT JOIN dc_pendaftaran AS p ON l.id_pendaftaran = p.id
WHERE p.id IS NULL
GROUP BY l.id_dokter, l.jenis, DATE(l.waktu)
ORDER BY jumlah_orphan DESC
LIMIT 10;

-- Buat Table Orphan
CREATE TABLE IF NOT EXISTS orphan_layanan AS
SELECT *
FROM dc_layanan_pendaftaran
WHERE 1=0;

-- Masukkan orphan ke table orphan_layanan (logging)
INSERT INTO orphan_layanan
SELECT l.*
FROM dc_layanan_pendaftaran AS l
LEFT JOIN dc_pendaftaran AS p ON l.id_pendaftaran = p.id
WHERE p.id IS NULL;

-- Buat fact table fact_layanan
CREATE TABLE IF NOT EXISTS fact_layanan (
    id INT PRIMARY KEY,
    id_pendaftaran INT,
    id_pasien INT,
    id_dokter INT,
    jenis VARCHAR(50),
    rawat VARCHAR(20),
    waktu_daftar DATETIME,
    waktu_keluar DATETIME,
    cara_bayar VARCHAR(20),
    kondisi VARCHAR(20)
);

-- Load layanan valid ke fact_layanan
INSERT INTO fact_layanan
SELECT 
    l.id,
    l.id_pendaftaran,
    p.id_pasien,
    l.id_dokter,
    l.jenis,
    p.rawat,
    p.waktu_daftar,
    p.waktu_keluar,
    l.cara_bayar,
    l.kondisi
FROM dc_layanan_pendaftaran AS l
JOIN dc_pendaftaran AS p ON l.id_pendaftaran = p.id
WHERE l.id_pendaftaran IS NOT NULL;

-- 1.4 Diagnosa Tanpa Layanan 
SELECT d.*
FROM dc_diagnosa d
LEFT JOIN dc_layanan_pendaftaran l 
ON d.id_layanan_pendaftaran = l.id
WHERE l.id IS NULL;

-- Buat Tabel Orphan
CREATE TABLE IF NOT EXISTS orphan_diagnosa AS
SELECT *
FROM dc_diagnosa
WHERE 1=0;

-- Masukkan orphan ke table orphan_diagnosa (logging)
INSERT INTO orphan_diagnosa
SELECT d.*
FROM dc_diagnosa d
LEFT JOIN dc_layanan_pendaftaran l 
  ON d.id_layanan_pendaftaran = l.id
WHERE l.id IS NULL;

-- Buat fact table fact_diagnosa
CREATE TABLE IF NOT EXISTS fact_diagnosa (
    id INT PRIMARY KEY,
    id_layanan_pendaftaran INT,
    id_pasien INT,
    id_dokter INT,
    kasus ENUM('baru','lama'),
    primer INT,
    kronis_farmasi INT,
    waktu DATETIME
);

-- Load layanan valid ke fact_diagnosa
INSERT INTO fact_diagnosa
SELECT 
    d.id,
    d.id_layanan_pendaftaran,
    p.id_pasien,
    d.id_dokter,
    d.kasus,
    d.primer,
    d.kronis_farmasi,
    d.waktu
FROM dc_diagnosa d
JOIN dc_layanan_pendaftaran l
  ON d.id_layanan_pendaftaran = l.id
JOIN dc_pendaftaran p
  ON l.id_pendaftaran = p.id;

-- 1.5 Resep Tanpa Layanan 
SELECT r.*
FROM dc_resep_tebus r
LEFT JOIN dc_layanan_pendaftaran l 
ON r.id_layanan_pendaftaran = l.id
WHERE l.id IS NULL;

-- Buat Tabel Orphan
CREATE TABLE IF NOT EXISTS orphan_resep AS
SELECT *
FROM dc_resep_tebus
WHERE 1=0;

-- Masukkan orphan ke table orphan_resep (logging)
INSERT INTO orphan_resep
SELECT r.*
FROM dc_resep_tebus r
LEFT JOIN dc_layanan_pendaftaran l 
  ON r.id_layanan_pendaftaran = l.id
WHERE l.id IS NULL;

-- Buat fact table fact_resep
CREATE TABLE IF NOT EXISTS fact_resep (
    id INT PRIMARY KEY,
    id_layanan_pendaftaran INT,
    id_pasien INT,
    id_dokter INT,
    tanggal_resep DATETIME,
    status_obat_pulang ENUM('ya','tidak'),
    jenis_resep VARCHAR(255),
    asal_resep VARCHAR(255)
);

-- Load layanan valid ke fact_resep
INSERT INTO fact_resep
SELECT 
    r.id,
    r.id_layanan_pendaftaran,
    r.id_pasien,
    r.id_dokter,
    r.tanggal_resep,
    r.status_obat_pulang,
    r.jenis_resep,
    r.asal_resep
FROM dc_resep_tebus r
JOIN dc_layanan_pendaftaran l
  ON r.id_layanan_pendaftaran = l.id;

-- 1.6 Resep Tanpa Pasien 
SELECT r.*
FROM dc_resep_tebus r
LEFT JOIN dc_pasien p 
ON r.id_pasien = p.id
WHERE p.id IS NULL;

-- 1.7 Resep R Tanpa Header 
SELECT rr.*
FROM dc_resep_tebus_r rr
LEFT JOIN dc_resep_tebus r 
ON rr.id_resep_tebus = r.id
WHERE r.id IS NULL;

-- Buat Table Orphan
CREATE TABLE IF NOT EXISTS orphan_resep_r AS
SELECT *
FROM dc_resep_tebus_r
WHERE 1=0;

-- Masukkan orphan ke table orphan_resep_r (logging)
INSERT INTO orphan_resep_r
SELECT rr.*
FROM dc_resep_tebus_r rr
LEFT JOIN dc_resep_tebus r 
  ON rr.id_resep_tebus = r.id
WHERE r.id IS NULL;

-- Buat fact table fact_resep_r
CREATE TABLE IF NOT EXISTS fact_resep_r (
    id INT PRIMARY KEY,
    id_resep_tebus INT,
    r_no SMALLINT,
    resep_r_jumlah DECIMAL(5,2),
    aturan_pakai VARCHAR(100),
    ket_aturan_pakai TEXT,
    timing ENUM('sebelum','sesudah','saat'),
    pemberian ENUM('pagi','siang','sore','malam'),
    jam TIME
);

-- Load layanan valid ke fact_resep_r
INSERT INTO fact_resep_r
SELECT 
    rr.id,
    rr.id_resep_tebus,
    rr.r_no,
    rr.resep_r_jumlah,
    rr.aturan_pakai,
    rr.ket_aturan_pakai,
    rr.timing,
    rr.pemberian,
    rr.jam
FROM dc_resep_tebus_r rr
JOIN dc_resep_tebus r
  ON rr.id_resep_tebus = r.id;

-- 1.8 Detail Tanpa R 
SELECT d.*
FROM dc_resep_tebus_r_detail d
LEFT JOIN dc_resep_tebus_r r 
ON d.id_resep_tebus_r = r.id
WHERE r.id IS NULL;

-- Buat Table Orphan
CREATE TABLE IF NOT EXISTS orphan_resep_r_detail AS
SELECT *
FROM dc_resep_tebus_r_detail
WHERE 1=0;

-- Masukkan orphan ke table orphan_resep_r_detail (logging)
INSERT INTO orphan_resep_r_detail
SELECT d.*
FROM dc_resep_tebus_r_detail d
LEFT JOIN dc_resep_tebus_r r
  ON d.id_resep_tebus_r = r.id
WHERE r.id IS NULL;

-- Buat fact table fact_resep_r_detail
CREATE TABLE IF NOT EXISTS fact_resep_r_detail (
    id INT PRIMARY KEY,
    id_resep_tebus_r INT,
    jual_harga DOUBLE,
    dosis_racik DOUBLE,
    jumlah_pakai DOUBLE,
    formularium ENUM('tidak','ya'),
    kronis TINYINT,
    nama_barang VARCHAR(100)
);

-- Load layanan valid ke fact_resep_r_detail
INSERT INTO fact_resep_r_detail
SELECT 
    d.id,
    d.id_resep_tebus_r,
    d.jual_harga,
    d.dosis_racik,
    d.jumlah_pakai,
    d.formularium,
    d.kronis,
    d.nama_barang
FROM dc_resep_tebus_r_detail d
JOIN dc_resep_tebus_r r
  ON d.id_resep_tebus_r = r.id;

-- Logical Time Check 
-- 2.1 Pendaftaran keluar sebelum daftar
SELECT *
FROM dc_pendaftaran
WHERE waktu_keluar IS NOT NULL
AND waktu_keluar < waktu_daftar;

-- Perbaiki Data waktu_daftar = waktu_keluar
UPDATE dc_pendaftaran
SET waktu_keluar = waktu_daftar
WHERE waktu_keluar < waktu_daftar;

-- 2.2 Layanan periksa sebelum daftar
SELECT *
FROM dc_layanan_pendaftaran
WHERE waktu_periksa IS NOT NULL
AND waktu_periksa < waktu;

-- Tambahkan kolom validasi & correction
ALTER TABLE dc_layanan_pendaftaran 
ADD COLUMN valid_time BOOLEAN DEFAULT 1, 
ADD COLUMN corrected_status_time BOOLEAN DEFAULT 0;

-- Flag record dimana waktu_periksa < waktu
UPDATE dc_layanan_pendaftaran
SET valid_time = 0
WHERE waktu_periksa IS NOT NULL
  AND waktu_periksa < waktu;

-- Perbaiki waktu_periksa supaya >= waktu pendaftaran
UPDATE dc_layanan_pendaftaran l
JOIN dc_pendaftaran p ON l.id_pendaftaran = p.id
SET l.waktu_periksa = p.waktu_daftar,
    l.valid_time = 1,
    l.corrected_status_time = 1
WHERE l.waktu_periksa < p.waktu_daftar;

-- Flag record dimana waktu_status_keluar < waktu_periksa
UPDATE dc_layanan_pendaftaran
SET corrected_status_time = 1
WHERE waktu_status_keluar IS NOT NULL 
  AND waktu_status_keluar < waktu_periksa;

-- Perbaiki waktu_status_keluar supaya >= waktu_periksa
UPDATE dc_layanan_pendaftaran
SET waktu_status_keluar = waktu_periksa
WHERE waktu_status_keluar IS NOT NULL 
  AND waktu_status_keluar < waktu_periksa;

-- Hasil audit setelah perbaikan
SELECT id, waktu, waktu_periksa, waktu_status_keluar, valid_time, corrected_status_time
FROM dc_layanan_pendaftaran
ORDER BY valid_time, corrected_status_time DESC;

-- 2.3 Umur Tidak Masuk Akal 
SELECT *
FROM dc_pasien
WHERE tanggal_lahir > CURDATE()
OR TIMESTAMPDIFF(YEAR, tanggal_lahir, CURDATE()) > 120;

-- Set NULL untuk yang tidak valid
UPDATE dc_pasien
SET tanggal_lahir = NULL
WHERE tanggal_lahir > CURDATE()
   OR TIMESTAMPDIFF(YEAR, tanggal_lahir, CURDATE()) > 120;

-- Value Check 
-- 3.1 Check active bukan 0/1 
SELECT DISTINCT active
FROM dc_pegawai;

-- 3.2 Check active bukan 0/1 
SELECT DISTINCT terklaim
FROM dc_layanan_pendaftaran;

-- Business Logic CHECK
-- 4.1 Diagnosa primer lebih dari 1 per layanan (1916)
SELECT id_layanan_pendaftaran, COUNT(*) jumlah_primer
FROM dc_diagnosa
WHERE primer = 1
GROUP BY id_layanan_pendaftaran
HAVING COUNT(*) > 1;

-- Pilih Diagnosa Primer Terbaru
WITH cte AS (
  SELECT id,
         id_layanan_pendaftaran,
         ROW_NUMBER() OVER(PARTITION BY id_layanan_pendaftaran ORDER BY waktu DESC) rn
  FROM dc_diagnosa
  WHERE primer = 1
)
UPDATE dc_diagnosa
SET primer = 0
WHERE id IN (
  SELECT id FROM cte WHERE rn > 1
);

-- 4.2 Resep Tanpa Detail (129)
SELECT r.id
FROM dc_resep_tebus r
LEFT JOIN dc_resep_tebus_r rr 
ON r.id = rr.id_resep_tebus
WHERE rr.id IS NULL;

-- Tandai resep Invalid
CREATE INDEX idx_rr_resep ON dc_resep_tebus_r(id_resep_tebus);

ALTER TABLE dc_resep_tebus ADD COLUMN valid_detail BOOLEAN DEFAULT 1;

UPDATE dc_resep_tebus r
LEFT JOIN dc_resep_tebus_r rr
  ON r.id = rr.id_resep_tebus
SET r.valid_detail = 0
WHERE rr.id IS NULL;

-- 4.3 Detail Obat Harga Negatif
SELECT *
FROM dc_resep_tebus_r_detail
WHERE jual_harga < 0;

-- 4.4 Jumlah Pakai 0 atau Negatif (61)
SELECT *
FROM dc_resep_tebus_r_detail
WHERE jumlah_pakai <= 0;

-- Hapus Invalid
DELETE FROM dc_resep_tebus_r_detail
WHERE jumlah_pakai <= 0;

-- Klaim CHECK
-- 5.1 Klaim Tanpa Pendaftaran (0)
SELECT c.*
FROM cbg_status_klaim c
LEFT JOIN dc_pendaftaran p 
ON c.id = p.id
WHERE p.id IS NULL;

-- 5.2 Klaim dengan tagihan negatif(0)
SELECT *
FROM cbg_status_klaim
WHERE tagihan_rs < 0 OR klaim < 0;

-- Distribusi Data
-- 6.1 Jumlah Pendaftaran Per Jenis
SELECT jenis, COUNT(*) 
FROM dc_pendaftaran
GROUP BY jenis;

-- 6.2 Cara Bayar Paling Sering
SELECT cara_bayar, COUNT(*) 
FROM dc_layanan_pendaftaran
GROUP BY cara_bayar;

-- 6.3 Status Klaim Distribusi
SELECT status_klaim, COUNT(*) 
FROM cbg_status_klaim
GROUP BY status_klaim;

-- Missing Value
-- 7.1 Missing critical fields - dc_pasien
SELECT
	COUNT(*) total,
	SUM(tanggal_daftar IS NULL) AS null_tgl_daftar,
	SUM(nama IS NULL OR TRIM(nama)='') AS null_nama,
	SUM(kelamin IS NULL) AS null_kelamin,
	SUM(tanggal_lahir IS NULL) AS null_tgl_lahir,
	SUM(agama IS NULL OR TRIM(agama)='') AS null_agama,
	SUM(gol_darah IS NULL) AS null_gol_darah,
	SUM(status_pernikahan IS NULL) AS null_status_pernikahan,
	SUM(alergi IS NULL) AS null_alergi,
	SUM(status IS NULL) AS null_status,
	SUM(is_kronis IS NULL or is_kronis = 'NULL') AS null_kronis
FROM dc_pasien;

-- Field tanggal lahir (1205) isi dengan median
SET @rowcount = (
    SELECT COUNT(*)
    FROM dc_pasien
    WHERE tanggal_lahir IS NOT NULL
);

SET @offset = FLOOR(@rowcount / 2);

SET @sql = CONCAT(
    'SELECT @median_tgl := tanggal_lahir 
     FROM dc_pasien
     WHERE tanggal_lahir IS NOT NULL
     ORDER BY tanggal_lahir
     LIMIT ', @offset, ',1'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT @median_tgl;

UPDATE dc_pasien
SET tanggal_lahir = @median_tgl
WHERE tanggal_lahir IS NULL;

-- Field alergi isi tidak diketahui (224701)
UPDATE dc_pasien
SET alergi = 'Tidak Diketahui'
WHERE alergi IS NULL;

-- Field is_kronis ganti 'NULL' dan null dengan string 'NULL' (23581)
UPDATE dc_pasien
SET is_kronis = 'NULL'
WHERE is_kronis IS NULL OR is_kronis = 'NULL';

-- Field Agama isi null dengan lain-lain (794) dan set default lain-lain
UPDATE dc_pasien
SET agama = 'Lain-lain'
WHERE agama IS NULL OR TRIM(agama) = '';

ALTER TABLE dc_pasien
MODIFY agama ENUM('Islam', 'Kristen', 'Katholik', 'Hindu', 'Budha', 'Lain-lain')
NOT NULL DEFAULT 'Lain-lain';

-- Field Gol-Darah isi dengan unknown (298244) dan set default unknown
ALTER TABLE dc_pasien
MODIFY gol_darah ENUM('A','B','AB','O','Unknown');

UPDATE dc_pasien
SET gol_darah = 'Unknown'
WHERE gol_darah IS NULL;

ALTER TABLE dc_pasien
MODIFY gol_darah ENUM('A','B','AB','O','Unknown') 
NOT NULL DEFAULT 'Unknown';

-- 7.2 Missing critical fields - dc_pegawai
SELECT
	COUNT(*) total,
	SUM(nama IS NULL OR TRIM(nama)='') AS null_nama,
	SUM(kelamin IS NULL) AS null_kelamin,
	SUM(agama IS NULL) AS agama,
	SUM(active IS NULL) AS active,
	SUM(status_pegawai IS NULL) AS null_status_pegawai
FROM dc_pegawai;

-- Field agama (11) dan set lain-lain
ALTER TABLE dc_pegawai
MODIFY agama ENUM('Islam', 'Kristen', 'Katholik', 'Hindu', 'Budha', 'Lain-lain');

UPDATE dc_pegawai
SET agama = 'Lain-lain'
WHERE agama IS NULL;

ALTER TABLE dc_pegawai
MODIFY agama ENUM('Islam', 'Kristen', 'Katholik', 'Hindu', 'Budha', 'Lain-lain')
NOT NULL DEFAULT 'Lain-lain';

-- 7.3 Missing critical fields - dc_pendaftaran
SELECT
	COUNT(*) total,
	SUM(no_register IS NULL OR TRIM(no_register)='') AS null_no_register,
	SUM(waktu_daftar IS NULL) AS null_waktu_daftar,
	SUM(waktu_keluar IS NULL) AS null_waktu_keluar,
	SUM(jenis IS NULL) AS null_jenis,
	SUM(rawat IS NULL) AS null_rawat,
	SUM(jenis_igd IS NULL) AS null_jenis_igd,
	SUM(kondisi_keluar IS NULL) AS null_kondisi_keluar,
	SUM(status IS NULL) AS null_status,
	SUM(keluar_rs IS NULL) AS null_keluar_rs,
	SUM(pakai_resep IS NULL) AS null_pakai_resep
FROM dc_pendaftaran;

-- Field waktu_keluar isi dengan waktu daftar jika rawat=jalan (72)
UPDATE dc_pendaftaran
SET waktu_keluar = waktu_daftar
WHERE waktu_keluar IS NULL
  AND rawat = 'Jalan';

-- Field jenis_igd isi tidak ada (189183) dan set default tidak ada
ALTER TABLE dc_pendaftaran
MODIFY jenis_igd ENUM('Umum','Kamar Bersalin','Hemodialisa','Kemoterapi','Ponek','Visum','Bedah','Anak','Kebidanan','Maternal','Bayi','Non Bedah','Psikiatrik','Geriatri', 'Tidak Ada');

UPDATE dc_pendaftaran
SET jenis_igd = 'Tidak Ada'
WHERE jenis_igd IS NULL;

ALTER TABLE dc_pendaftaran
MODIFY jenis_igd ENUM('Umum','Kamar Bersalin','Hemodialisa','Kemoterapi','Ponek','Visum','Bedah','Anak','Kebidanan','Maternal','Bayi','Non Bedah','Psikiatrik','Geriatri', 'Tidak Ada')
NOT NULL DEFAULT 'Tidak Ada';

-- Field kondisi_keluar isi hidup dan set default hidup (24)
UPDATE dc_pendaftaran
SET kondisi_keluar = 'Hidup'
WHERE kondisi_keluar IS NULL;

ALTER TABLE dc_pendaftaran
MODIFY kondisi_keluar ENUM('Hidup', 'Meninggal')
NOT NULL DEFAULT 'Hidup';

-- 7.4 Missing critical fields - dc_resep_tebus
SELECT
	COUNT(*) total,
	SUM(id IS NULL) AS null_id,
	SUM(tanggal_resep IS NULL) AS null_tgl_resep,
	SUM(status_obat_pulang IS NULL) AS null_status_obat_pulang,
	SUM(jenis_resep IS NULL) AS null_jenis_resep,
	SUM(asal_resep IS NULL) AS null_asal_resep
FROM dc_resep_tebus;

-- Field status_obat_pulang isi tidak diketahui dan set default (10347)
ALTER TABLE dc_resep_tebus
MODIFY status_obat_pulang ENUM('Ya', 'Tidak', 'Tidak Diketahui');

UPDATE dc_resep_tebus
SET status_obat_pulang = 'Tidak Diketahui'
WHERE status_obat_pulang IS NULL OR TRIM(status_obat_pulang) = '';

ALTER TABLE dc_resep_tebus
MODIFY status_obat_pulang ENUM('Ya', 'Tidak', 'Tidak Diketahui')
NOT NULL DEFAULT 'Tidak Diketahui';

-- Field jenis_resep isi dengan lain-lain (11168)
ALTER TABLE dc_resep_tebus
MODIFY jenis_resep ENUM('Racikan', 'Non Racikan', 'Lain-lain');

UPDATE dc_resep_tebus
SET jenis_resep = 'Lain-lain'
WHERE jenis_resep IS NULL OR TRIM(jenis_resep) = '';

-- Field asal_resep isi dengan unknown (17352)
UPDATE dc_resep_tebus
SET asal_resep = 'Unknown'
WHERE asal_resep IS NULL;

-- 7.5 Missing critical fields - dc_resep_tebus_r
SELECT
	COUNT(*) total,
	SUM(r_no IS NULL) AS null_r_no,
	SUM(resep_r_jumlah IS NULL) AS null_resep_r,
	SUM(aturan_pakai IS NULL OR aturan_pakai = '-' OR TRIM(aturan_pakai)='') AS null_aturan_pakai,
	SUM(ket_aturan_pakai IS NULL) AS null_ket_aturan_pakai,
	SUM(timing IS NULL) AS null_timing,
	SUM(pemberian IS NULL) AS null_pemberian,
	SUM(jam IS NULL) AS null_jam
FROM dc_resep_tebus_r;

-- Field aturan_pakai isi tidak diketahui (257576)
UPDATE dc_resep_tebus_r
SET aturan_pakai = 'Tidak Diketahui'
WHERE aturan_pakai IS NULL OR TRIM(aturan_pakai) = '-' OR TRIM(aturan_pakai) = '';

-- Field timing isi tidak diketahui (231623)
ALTER TABLE dc_resep_tebus_r
MODIFY timing ENUM('Sebelum', 'Sesudah', 'Saat', 'Tidak Diketahui');

UPDATE dc_resep_tebus_r
SET timing = 'Tidak Diketahui'
WHERE timing IS NULL;

-- Field pemberian isi tidak diketahui (383753)
ALTER TABLE dc_resep_tebus_r
MODIFY pemberian ENUM('Pagi', 'Siang', 'Sore', 'Malam', 'Tidak Diketahui');

UPDATE dc_resep_tebus_r
SET pemberian = 'Tidak Diketahui'
WHERE pemberian IS NULL;

-- Field jam isi dengan 00:00:00 (383753)
UPDATE dc_resep_tebus_r
SET jam = '00:00:00'
WHERE jam IS NULL;

ALTER TABLE dc_resep_tebus_r
MODIFY jam TIME NOT NULL DEFAULT '00:00:00';

-- 7.6 Missing critical fields - dc_resep_tebus_r_detail
SELECT
	COUNT(*) total,
	SUM(jual_harga IS NULL) AS null_jual_harga,
	SUM(dosis_racik IS NULL) AS null_dosis_racik,
	SUM(jumlah_pakai IS NULL) AS null_jml_pakai,
	SUM(formularium IS NULL) AS null_formularium,
	SUM(kronis IS NULL) AS null_kronis,
	SUM(nama_barang IS NULL OR TRIM(nama_barang)='') AS null_nama_barang
FROM dc_resep_tebus_r_detail;

-- Field formularium isi dengan tidak karena formularium adalah daftar resmi obat rs dan set default tidak (361989)
UPDATE dc_resep_tebus_r_detail
SET formularium = 'Tidak'
WHERE formularium IS NULL;

ALTER TABLE dc_resep_tebus_r_detail
MODIFY formularium ENUM('Tidak','Ya')
NOT NULL DEFAULT 'Tidak';

-- 7.7 Missing critical fields - dc_nakes
SELECT
	COUNT(*) total,
	SUM(kode_spesialisasi IS NULL OR TRIM(kode_spesialisasi)='') AS null_kd_spesialisasi,
	SUM(nama_spesialisasi IS NULL OR TRIM(nama_spesialisasi)='') AS null_nm_spesialisasi,
	SUM(tgl_mulai_praktek IS NULL) AS null_tgl_mulai_praktek,
	SUM(nama_profesi IS NULL OR TRIM(nama_profesi)='') AS null_nm_profesi
FROM dc_nakes;

-- Checking
SELECT 
    n.id_pegawai,
    n.kode_spesialisasi,
    n.nama_spesialisasi,
    n.nama_profesi,
    p.active,
    p.status_pegawai
FROM dc_nakes n
LEFT JOIN dc_pegawai p
    ON n.id_pegawai = p.id
WHERE n.kode_spesialisasi IS NULL OR n.nama_spesialisasi IS NULL
ORDER BY n.nama_profesi, n.id_pegawai;

-- Field kode_spesialisasi dan nama_spesialisasi isi umum untuk dokter tetap, non untuk dokter non pegawai dan non dokter (25)
-- Dokter tetap → umum
UPDATE dc_nakes n
JOIN dc_pegawai p ON n.id_pegawai = p.id
SET n.kode_spesialisasi = 'UMU',
    n.nama_spesialisasi = 'Umum'
WHERE (n.kode_spesialisasi IS NULL OR n.nama_spesialisasi IS NULL)
  AND n.nama_profesi LIKE 'Dokter%'
  AND p.status_pegawai = 'pegawai';

-- Dokter tamu / non-dokter → Non Spesialis
UPDATE dc_nakes n
JOIN dc_pegawai p ON n.id_pegawai = p.id
SET n.kode_spesialisasi = 'NON',
    n.nama_spesialisasi = 'Non Spesialis'
WHERE (n.kode_spesialisasi IS NULL OR n.nama_spesialisasi IS NULL)
  AND (n.nama_profesi NOT LIKE 'Dokter%' OR p.status_pegawai != 'pegawai');

-- 7.8 Missing critical fields - dc_layanan_pendaftaran
SELECT
	COUNT(*) total,
	SUM(waktu IS NULL) AS null_waktu,
	SUM(waktu_periksa IS NULL) AS null_waktu_periksa,
	SUM(waktu_status_keluar IS NULL) AS null_waktu_status_keluar,
	SUM(jenis IS NULL) AS null_jenis,
	SUM(kondisi IS NULL) AS null_kondisi,
	SUM(status IS NULL) AS null_status,
	SUM(cara_bayar IS NULL) AS null_cara_bayar,
	SUM(terklaim IS NULL) AS null_terklaim,
	SUM(tindak_lanjut IS NULL) AS null_tindak_lanjut,
	SUM(triase_primer IS NULL) AS null_triase_primer,
	SUM(jenis_lab IS NULL) AS null_jenis_lab
FROM dc_layanan_pendaftaran;

SELECT 
    lp.id AS id_layanan,
    lp.id_pendaftaran,
    lp.waktu,
    lp.waktu_periksa,
    lp.waktu_status_keluar,
    p.waktu_daftar,
    p.waktu_keluar AS waktu_keluar_rs,
    lp.jenis AS jenis_layanan,
    lp.kondisi,
    lp.tindak_lanjut,
    
    p.no_register,
    p.jenis AS jenis_pendaftaran,
    p.rawat,
    p.jenis_igd,
    p.status AS status_pendaftaran,
    p.keluar_rs
FROM dc_layanan_pendaftaran lp
LEFT JOIN dc_pendaftaran p
    ON lp.id_pendaftaran = p.id
LIMIT 100;

-- Field status isi belum dan set default belum (19363)
UPDATE dc_layanan_pendaftaran
SET status = 'Belum'
WHERE status IS NULL;

ALTER TABLE dc_layanan_pendaftaran
MODIFY status ENUM('Belum','Sedang','Sudah','Batal')
NOT NULL DEFAULT 'Belum';

-- Field tindak_lanjut isi lain-lain(16638)
UPDATE dc_layanan_pendaftaran
SET tindak_lanjut = 'Lain - lain'
WHERE tindak_lanjut IS NULL;

-- Field jenis_lab isi tidak ada dan set default(354303)
ALTER TABLE dc_layanan_pendaftaran
MODIFY jenis_lab ENUM('Laboratorium PCR','Laboratorium Klinik','Laboratorium PA','Bank Darah','Mikrobiologi', 'Tidak Ada');

UPDATE dc_layanan_pendaftaran
SET jenis_lab = 'Tidak Ada'
WHERE jenis_lab IS NULL OR TRIM(jenis_lab) = '';

ALTER TABLE dc_layanan_pendaftaran
MODIFY jenis_lab ENUM('Laboratorium PCR','Laboratorium Klinik','Laboratorium PA','Bank Darah','Mikrobiologi', 'Tidak Ada')
NOT NULL DEFAULT 'Tidak Ada';

-- Field triase_primer isi 0 (334115)
UPDATE dc_layanan_pendaftaran
SET triase_primer = 0 
WHERE triase_primer IS NULL;

-- Field waktu_periksa isi dengan waktu (53824)
UPDATE dc_layanan_pendaftaran
SET waktu_periksa = waktu
WHERE waktu_periksa IS NULL;

-- Field waktu_status_keluar isi dengan waktu (38281)
UPDATE dc_layanan_pendaftaran
SET waktu_status_keluar = waktu
WHERE waktu_status_keluar IS NULL;

-- 7.9 Missing critical fields - dc_golongan_sebab_sakit
SELECT
	COUNT(*) total,
	SUM(no_daftar_terperinci IS NULL OR TRIM(no_daftar_terperinci)='') AS null_no_terperinci,
	SUM(nama IS NULL OR TRIM(nama)='') AS null_nama,
	SUM(alias IS NULL) AS null_alias,
	SUM(menular IS NULL) AS null_menular,
	SUM(is_kronis IS NULL OR is_kronis='NULL') AS null_kronis,
	SUM(status IS NULL) AS null_status,
	SUM(versi IS NULL) AS null_versi,
	SUM(checked IS NULL) AS null_checked
FROM dc_golongan_sebab_sakit;

-- Field alias isi tidak ada (968)
UPDATE dc_golongan_sebab_sakit
SET alias = 'Tidak Ada'
WHERE alias IS NULL;

-- Field status isi 1 (968)
UPDATE dc_golongan_sebab_sakit
SET status = 1 
WHERE status IS NULL;

-- Field is kronis isi null dengan 'NULL' string
UPDATE dc_golongan_sebab_sakit
SET is_kronis = 'NULL'
WHERE is_kronis IS NULL;

-- 8.0 Missing critical fields - dc_diagnosa
SELECT
	COUNT(*) total,
	SUM(waktu IS NULL) AS null_waktu,
	SUM(kasus IS NULL) AS null_kasus,
	SUM(primer IS NULL) AS null_primer,
	SUM(id_users IS NULL) AS null_id_users,
	SUM(kronis_farmasi IS NULL) AS null_kronis_farmasi
FROM dc_diagnosa;

-- Ada dokter yang mengisi diagnosa sendiri yaitu id 5 atau 00005
SELECT 
    d.id AS diagnosa_id,
    d.id_dokter,
    d.id_users,
    n.id_pegawai,
    n.nama_spesialisasi,
    n.nama_profesi
FROM dc_diagnosa d
INNER JOIN dc_nakes n
    ON d.id_dokter = n.id
WHERE d.id_dokter IS NOT NULL
  AND d.id_users IS NOT NULL
  AND n.id_pegawai IS NOT NULL
  AND n.nama_spesialisasi IS NOT NULL
  AND n.nama_profesi IS NOT NULL
ORDER BY d.id
LIMIT 100;

-- Field id_users (126134)
UPDATE dc_diagnosa
SET id_users = 0
WHERE id_users IS NULL;

-- 8.1 Missing critical fields - cbg_status_klaim
SELECT
	COUNT(*) total,
	SUM(waktu IS NULL) AS null_waktu,
	SUM(waktu_update IS NULL) AS null_waktu_update,
	SUM(waktu_final IS NULL) AS null_waktu_final,
	SUM(waktu_sent IS NULL) AS null_waktu_sent,
	SUM(notifikasi IS NULL) AS null_notifikasi,
	SUM(cbg_code IS NULL) AS null_cbg_code,
	SUM(status_klaim IS NULL) AS null_status_klaim,
	SUM(status_klaim_idrg IS NULL) AS null_status_klaim_idrg,
	SUM(upload IS NULL) AS null_upload,
	SUM(tagihan_rs IS NULL) AS null_tagihan_rs,
	SUM(klaim IS NULL) AS null_klaim,
	SUM(upload_doc IS NULL OR upload_doc='-') AS null_upload_doc
FROM cbg_status_klaim;

-- Field cbg_code isi unknown (17836)
UPDATE cbg_status_klaim
SET cbg_code = 'Unknown'
WHERE cbg_code IS NULL OR TRIM(cbg_code) = '';

-- Field status_klaim_idrg isi Tidak Diketahui (17397)
ALTER TABLE cbg_status_klaim
MODIFY status_klaim_idrg ENUM('add_claim','set_claim','grouping_idrg_fail','grouping_idrg_success','final_idrg','grouping_inacbg_1_fail','grouping_inacbg_1_success','grouping_inacbg_2','final_inacbg','final_claim','send_claim', 'tidak_diketahui');

UPDATE cbg_status_klaim
SET status_klaim_idrg = 'tidak_diketahui'
WHERE status_klaim_idrg IS NULL OR TRIM(status_klaim_idrg) = '';

-- Field upload_doc isi dengan tidak ada (456)
UPDATE cbg_status_klaim
SET upload_doc = '-'
WHERE upload_doc IS NULL OR TRIM(upload_doc) = '';

ALTER TABLE cbg_status_klaim
MODIFY upload_doc ENUM('-', 'prepared', 'uploaded', 'tidak ada');

UPDATE cbg_status_klaim
SET upload_doc = 'tidak ada'
WHERE upload_doc = '-';

ALTER TABLE cbg_status_klaim
MODIFY upload_doc ENUM('tidak ada', 'prepared', 'uploaded');

-- Check pola waktu final
SELECT 
  COUNT(*) total,
  SUM(waktu_final IS NULL) null_final,
  SUM(waktu_sent IS NULL) null_sent,
  SUM(status_klaim = 'Final') total_final_status,
  SUM(status_klaim_idrg = 'send_claim') total_sent_status
FROM cbg_status_klaim;

-- Isi waktu_final dengan waktu update jika status_klaim = final (25840)
UPDATE cbg_status_klaim
SET waktu_final = waktu_update
WHERE waktu_final IS NULL
AND status_klaim = 'Final';

-- Isi waktu_sent dengan waktu_update (61288)
UPDATE cbg_status_klaim
SET waktu_sent = waktu_update
WHERE waktu_sent IS NULL
AND status_klaim_idrg = 'send_claim';

-- Samakan data type
ALTER TABLE cbg_status_klaim
MODIFY waktu_update DATETIME;

ALTER TABLE dc_pasien
MODIFY tanggal_daftar DATETIME;

ALTER TABLE dc_resep_tebus_r
MODIFY jam DATETIME;

ALTER TABLE dc_golongan_sebab_sakit
MODIFY is_kronis ENUM('YA', 'TIDAK', 'Tidak Diketahui', 'NULL');

UPDATE dc_golongan_sebab_sakit
SET is_kronis = 'Tidak Diketahui'
WHERE is_kronis = 'NULL';

ALTER TABLE dc_golongan_sebab_sakit
MODIFY is_kronis ENUM('YA', 'TIDAK', 'Tidak Diketahui');

ALTER TABLE dc_pasien
MODIFY is_kronis ENUM('YA', 'TIDAK', 'Tidak Diketahui', 'NULL');

UPDATE dc_pasien
SET is_kronis = 'Tidak Diketahui'
WHERE is_kronis = 'NULL';

ALTER TABLE dc_pasien
MODIFY is_kronis ENUM('YA', 'TIDAK', 'Tidak Diketahui');