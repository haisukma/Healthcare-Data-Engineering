-- Diagnosa Margin Tertinggi Tahun 2025
SELECT 
    gs.nama AS nama_penyakit,
    SUM(c.tagihan_rs) AS total_tagihan,
    SUM(c.klaim) AS total_klaim,
    SUM(c.tagihan_rs - c.klaim) AS total_margin
FROM dc_pendaftaran d
JOIN cbg_status_klaim c 
    ON c.id = d.id
JOIN dc_layanan_pendaftaran lp 
    ON lp.id_pendaftaran = d.id
JOIN dc_diagnosa dx 
    ON dx.id_layanan_pendaftaran = lp.id
JOIN dc_golongan_sebab_sakit gs 
    ON gs.id = dx.id_golongan_sebab_sakit
WHERE YEAR(c.waktu) = 2025
GROUP BY gs.nama
ORDER BY total_margin DESC;

-- Diagnosa Margin Terendah Tahun 2025
SELECT 
    gs.nama AS nama_penyakit,
    SUM(c.tagihan_rs) AS total_tagihan,
    SUM(c.klaim) AS total_klaim,
    SUM(c.tagihan_rs - c.klaim) AS total_margin
FROM dc_pendaftaran d
JOIN cbg_status_klaim c 
    ON c.id = d.id
JOIN dc_layanan_pendaftaran lp 
    ON lp.id_pendaftaran = d.id
JOIN dc_diagnosa dx 
    ON dx.id_layanan_pendaftaran = lp.id
JOIN dc_golongan_sebab_sakit gs 
    ON gs.id = dx.id_golongan_sebab_sakit
WHERE YEAR(c.waktu) = 2025
GROUP BY gs.nama
ORDER BY total_margin ASC;

-- Apakah Pemilihan Obat Mempengaruhi Kerugian
SELECT 
    gs.nama AS nama_penyakit,
    rdet.nama_barang,
    SUM(c.tagihan_rs - c.klaim) AS total_margin,
    SUM(rdet.jumlah_pakai) AS total_qty
FROM dc_pendaftaran d
JOIN cbg_status_klaim c 
    ON c.id = d.id
JOIN dc_layanan_pendaftaran lp 
    ON lp.id_pendaftaran = d.id
JOIN dc_diagnosa dx 
    ON dx.id_layanan_pendaftaran = lp.id
JOIN dc_golongan_sebab_sakit gs 
    ON gs.id = dx.id_golongan_sebab_sakit
JOIN dc_resep_tebus rt 
    ON rt.id_layanan_pendaftaran = lp.id
JOIN dc_resep_tebus_r r 
    ON r.id_resep_tebus = rt.id
JOIN dc_resep_tebus_r_detail rdet 
    ON rdet.id_resep_tebus_r = r.id
WHERE YEAR(c.waktu) = 2025
GROUP BY gs.nama, rdet.nama_barang
HAVING SUM(c.tagihan_rs - c.klaim) < 0
ORDER BY total_margin ASC;

-- Penyakit Paling Sering Per 2025
SELECT 
    MONTH(c.waktu) AS bulan,
    gs.nama AS nama_penyakit,
    COUNT(*) AS jumlah_kasus
FROM dc_pendaftaran d
JOIN cbg_status_klaim c 
    ON c.id = d.id
JOIN dc_layanan_pendaftaran lp 
    ON lp.id_pendaftaran = d.id
JOIN dc_diagnosa dx 
    ON dx.id_layanan_pendaftaran = lp.id
JOIN dc_golongan_sebab_sakit gs 
    ON gs.id = dx.id_golongan_sebab_sakit
WHERE YEAR(c.waktu) = 2025
GROUP BY bulan, gs.nama
ORDER BY bulan, jumlah_kasus DESC;

-- Distribusi Diagnosa Berdasarkan Umur
SELECT 
    CASE
        WHEN TIMESTAMPDIFF(YEAR, p.tanggal_lahir, c.waktu) BETWEEN 0 AND 17 THEN '0-17'
        WHEN TIMESTAMPDIFF(YEAR, p.tanggal_lahir, c.waktu) BETWEEN 18 AND 40 THEN '18-40'
        WHEN TIMESTAMPDIFF(YEAR, p.tanggal_lahir, c.waktu) BETWEEN 41 AND 60 THEN '41-60'
        ELSE '60+'
    END AS kelompok_umur,
    gs.nama AS nama_penyakit,
    COUNT(*) AS jumlah_kasus
FROM dc_pasien p
JOIN dc_pendaftaran d ON d.id_pasien = p.id
JOIN cbg_status_klaim c ON c.id = d.id
JOIN dc_layanan_pendaftaran lp ON lp.id_pendaftaran = d.id
JOIN dc_diagnosa dx ON dx.id_layanan_pendaftaran = lp.id
JOIN dc_golongan_sebab_sakit gs ON gs.id = dx.id_golongan_sebab_sakit
WHERE YEAR(c.waktu) = 2025
GROUP BY kelompok_umur, gs.nama
ORDER BY kelompok_umur, jumlah_kasus DESC;

-- Rata-rata Durasi Klaim per Kode CBG
SELECT 
    c.cbg_code,
    COUNT(*) AS jumlah_klaim,
    ROUND(AVG(TIMESTAMPDIFF(HOUR, c.waktu, c.waktu_update)), 2) 
        AS avg_durasi_jam
FROM cbg_status_klaim c
WHERE YEAR(c.waktu) = 2025
  AND c.waktu_update IS NOT NULL
GROUP BY c.cbg_code
ORDER BY avg_durasi_jam ASC;

-- 10 CBG Tercepat
SELECT *
FROM (
    SELECT 
        c.cbg_code,
        COUNT(*) AS jumlah_klaim,
        ROUND(AVG(TIMESTAMPDIFF(HOUR, c.waktu, c.waktu_update)), 2) 
            AS avg_durasi_jam
    FROM cbg_status_klaim c
    WHERE YEAR(c.waktu) = 2025
      AND c.waktu_update IS NOT NULL
    GROUP BY c.cbg_code
) t
ORDER BY avg_durasi_jam ASC
LIMIT 10;

-- 10 CBG Terlama
SELECT *
FROM (
    SELECT 
        c.cbg_code,
        COUNT(*) AS jumlah_klaim,
        ROUND(AVG(TIMESTAMPDIFF(HOUR, c.waktu, c.waktu_update)), 2) 
            AS avg_durasi_jam
    FROM cbg_status_klaim c
    WHERE YEAR(c.waktu) = 2025
      AND c.waktu_update IS NOT NULL
    GROUP BY c.cbg_code
) t
ORDER BY avg_durasi_jam DESC
LIMIT 10;

-- Profit / Kerugian Bulanan Klaim Belum Final 
SELECT 
    MONTH(c.waktu) AS bulan,
    COUNT(*) AS jumlah_klaim_belum_final,
    SUM(c.tagihan_rs) AS total_tagihan,
    SUM(c.klaim) AS total_klaim,
    SUM(c.tagihan_rs - c.klaim) AS total_margin
FROM cbg_status_klaim c
WHERE YEAR(c.waktu) = 2025
  AND c.status_klaim NOT IN ('Final', 'Cair')
GROUP BY MONTH(c.waktu)
ORDER BY bulan;