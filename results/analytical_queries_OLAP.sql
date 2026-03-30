-- Analisis 2: Tren Penyakit Berdasarkan Umur Pasien
WITH diagnosa_umur AS (
    SELECT
        dp.kelompok_umur,
        d.nama_penyakit,
        COUNT(*) AS jumlah_kasus,
        ROW_NUMBER() OVER (
            PARTITION BY dp.kelompok_umur
            ORDER BY COUNT(*) DESC
        ) AS rn
    FROM fact_klaim fk
    JOIN dim_pasien dp
        ON fk.pasien_key = dp.pasien_key
    JOIN fact_resep_detail fr
        ON fk.pendaftaran_id = fr.pendaftaran_id
    JOIN dim_diagnosa d
        ON fr.diagnosa_key = d.diagnosa_key
    GROUP BY dp.kelompok_umur, d.nama_penyakit
)

SELECT 
    kelompok_umur,
    nama_penyakit,
    jumlah_kasus
FROM diagnosa_umur
WHERE rn <= 5
ORDER BY kelompok_umur, jumlah_kasus DESC;

-- 10 CBG Durasi Tercepat
SELECT 
    dc.kode_cbg,
    ROUND(AVG(fk.durasi_klaim_jam), 2) AS avg_durasi_jam
FROM fact_klaim fk
JOIN dim_time dt 
    ON fk.time_key = dt.time_key
JOIN dim_cbg dc 
    ON fk.cbg_key = dc.cbg_key
WHERE dt.tahun = 2025
GROUP BY dc.kode_cbg
ORDER BY avg_durasi_jam ASC
LIMIT 10;

-- 10 CBG Durasi Terlama
SELECT 
    dc.kode_cbg,
    ROUND(AVG(fk.durasi_klaim_jam), 2) AS avg_durasi_jam
FROM fact_klaim fk
JOIN dim_time dt 
    ON fk.time_key = dt.time_key
JOIN dim_cbg dc 
    ON fk.cbg_key = dc.cbg_key
WHERE dt.tahun = 2025
GROUP BY dc.kode_cbg
ORDER BY avg_durasi_jam DESC
LIMIT 10;

-- Analisis Klaim Belum Final + Profit/Kerugian per Bulan (2025) --> Okto&Nov melonjak ekstrem dibanding bulan lain. Mungkin ada batch update massal atau ada duplikasi
SELECT 
    dt.bulan,
    dt.nama_bulan,
    COUNT(*) AS jumlah_klaim_belum_final,
    ROUND(SUM(fk.margin), 2) AS total_profit_atau_rugi
FROM fact_klaim fk
JOIN dim_time dt 
    ON fk.time_key = dt.time_key
JOIN dim_status_klaim ds 
    ON fk.status_key = ds.status_key
WHERE dt.tahun = 2025
AND ds.status_klaim IN ('Not Yet', 'Added', 'Saved', 'Grouper Stage 1')
GROUP BY dt.bulan, dt.nama_bulan
ORDER BY dt.bulan;

SELECT 
    dt.bulan,
    dt.nama_bulan,
    SUM(CASE WHEN fk.margin > 0 THEN fk.margin ELSE 0 END) AS total_profit,
    SUM(CASE WHEN fk.margin < 0 THEN fk.margin ELSE 0 END) AS total_rugi
FROM fact_klaim fk
JOIN dim_time dt 
    ON fk.time_key = dt.time_key
JOIN dim_status_klaim ds 
    ON fk.status_key = ds.status_key
WHERE dt.tahun = 2025
AND ds.status_klaim IN ('Not Yet', 'Added', 'Saved', 'Grouper Stage 1')
GROUP BY dt.bulan, dt.nama_bulan
ORDER BY dt.bulan;


SELECT cbg_key
FROM dim_cbg