-- Create Dimensions Table 
-- DIM_TIME
CREATE TABLE dim_time (
    time_key INT PRIMARY KEY AUTO_INCREMENT,
    tanggal DATE,
    bulan INT,
    nama_bulan VARCHAR(20),
    tahun INT,
    kuartal INT
);

-- Insert dari cbg_status_klaim.waktu
INSERT INTO dim_time (tanggal, bulan, nama_bulan, tahun, kuartal)
SELECT DISTINCT
    DATE(waktu) AS tanggal,
    MONTH(waktu) AS bulan,
    MONTHNAME(waktu) AS nama_bulan,
    YEAR(waktu) AS tahun,
    QUARTER(waktu) AS kuartal
FROM farma_teknologi_new.cbg_status_klaim;

-- DIM_PASIEN
CREATE TABLE dim_pasien (
    pasien_key INT PRIMARY KEY AUTO_INCREMENT,
    id_pasien INT,
    nama_pasien VARCHAR(100),
    jenis_kelamin VARCHAR(20),
    tanggal_lahir DATE,
    umur_saat_klaim INT,
    kelompok_umur VARCHAR(20)
);

-- Insert dari dc_pasien dan hitung umur
INSERT INTO dim_pasien (
    id_pasien,
    nama_pasien,
    jenis_kelamin,
    tanggal_lahir,
    umur_saat_klaim,
    kelompok_umur
)
SELECT DISTINCT
    p.id,
    p.nama,
    p.kelamin,
    p.tanggal_lahir,
    TIMESTAMPDIFF(YEAR, p.tanggal_lahir, c.waktu) AS umur,
    CASE
        WHEN TIMESTAMPDIFF(YEAR, p.tanggal_lahir, c.waktu) BETWEEN 0 AND 17 THEN '0-17'
        WHEN TIMESTAMPDIFF(YEAR, p.tanggal_lahir, c.waktu) BETWEEN 18 AND 40 THEN '18-40'
        WHEN TIMESTAMPDIFF(YEAR, p.tanggal_lahir, c.waktu) BETWEEN 41 AND 60 THEN '41-60'
        ELSE '60+'
    END AS kelompok_umur
FROM farma_teknologi_new.dc_pasien p
JOIN farma_teknologi_new.dc_pendaftaran d ON d.id_pasien = p.id
JOIN farma_teknologi_new.cbg_status_klaim c ON c.id = d.id;

-- DIM_DOKTER
CREATE TABLE dim_dokter (
    dokter_key INT PRIMARY KEY AUTO_INCREMENT,
    id_dokter INT,
    nama_dokter VARCHAR(100),
    spesialisasi VARCHAR(100),
    profesi VARCHAR(50),
    status_pegawai VARCHAR(50)
);

-- Insert dari dc_nakes dan dc_pegawai
INSERT INTO dim_dokter (
    id_dokter,
    nama_dokter,
    spesialisasi,
    profesi,
    status_pegawai
)
SELECT DISTINCT
    n.id,
    p.nama,
    n.nama_spesialisasi,
    n.nama_profesi,
    p.status_pegawai
FROM farma_teknologi_new.dc_nakes n
LEFT JOIN farma_teknologi_new.dc_pegawai p 
    ON p.id = n.id_pegawai;

-- DIM_DIAGNOSA
CREATE TABLE dim_diagnosa (
    diagnosa_key INT PRIMARY KEY AUTO_INCREMENT,
    kode_penyakit VARCHAR(20),
    nama_penyakit VARCHAR(200),
    golongan VARCHAR(100),
    menular VARCHAR(10),
    kronis VARCHAR(50)
);

-- Insert dari dc_golongan_sebab_sakit
INSERT INTO dim_diagnosa (
    kode_penyakit,
    nama_penyakit,
    golongan,
    menular,
    kronis
)
SELECT DISTINCT
    g.no_daftar_terperinci,
    g.nama,
    g.versi,
    g.menular,
    g.is_kronis
FROM farma_teknologi_new.dc_golongan_sebab_sakit g;

-- DIM_OBAT
CREATE TABLE dim_obat (
    obat_key INT PRIMARY KEY AUTO_INCREMENT,
    nama_barang VARCHAR(200),
    formularium VARCHAR(10),
    kronis VARCHAR(10)
);

-- Insert dari dc_resep_tebus_r_detail
INSERT INTO dim_obat (
    nama_barang,
    formularium,
    kronis
)
SELECT DISTINCT
    nama_barang,
    formularium,
    kronis
FROM farma_teknologi_new.dc_resep_tebus_r_detail;

-- DIM_CBG
CREATE TABLE dim_cbg (
    cbg_key INT PRIMARY KEY AUTO_INCREMENT,
    kode_cbg VARCHAR(50),
    deskripsi_cbg VARCHAR(200)
);

-- Insert dari cbg_status_klaim
INSERT INTO dim_cbg (
    kode_cbg,
    deskripsi_cbg
)
SELECT DISTINCT
    cbg_code,
    status_klaim_idrg
FROM farma_teknologi_new.cbg_status_klaim;

-- DIM_STATUS_KLAIM
CREATE TABLE dim_status_klaim (
    status_key INT PRIMARY KEY AUTO_INCREMENT,
    status_klaim VARCHAR(50),
    upload VARCHAR(10),
    upload_doc VARCHAR(10)
);

-- Insert dari cbg_status_klaim
INSERT INTO dim_status_klaim (
    status_klaim,
    upload,
    upload_doc
)
SELECT DISTINCT
    status_klaim,
    upload,
    upload_doc
FROM farma_teknologi_new.cbg_status_klaim;

-- Create Fact Klaim
CREATE TABLE fact_klaim (
    fact_klaim_id INT PRIMARY KEY AUTO_INCREMENT,
    pendaftaran_id INT,
    time_key INT,
    pasien_key INT,
    dokter_key INT,
    cbg_key INT,
    status_key INT,
    total_tagihan DECIMAL(18,2),
    total_klaim DECIMAL(18,2),
    margin DECIMAL(18,2),
    durasi_klaim_jam DECIMAL(10,2),
    jumlah_resep INT,
    jumlah_obat INT,
    jumlah_diagnosa INT,

    FOREIGN KEY (time_key) REFERENCES dim_time(time_key),
    FOREIGN KEY (pasien_key) REFERENCES dim_pasien(pasien_key),
    FOREIGN KEY (dokter_key) REFERENCES dim_dokter(dokter_key),
    FOREIGN KEY (cbg_key) REFERENCES dim_cbg(cbg_key),
    FOREIGN KEY (status_key) REFERENCES dim_status_klaim(status_key)
);

CREATE INDEX idx_dim_time_tanggal ON dim_time(tanggal);
CREATE INDEX idx_dim_pasien_idpasien ON dim_pasien(id_pasien);
CREATE INDEX idx_dim_dokter_iddokter ON dim_dokter(id_dokter);
CREATE INDEX idx_dim_cbg_kode ON dim_cbg(kode_cbg);
CREATE INDEX idx_dim_status_klaim ON dim_status_klaim(status_klaim);

CREATE INDEX idx_lp_idpendaftaran 
ON farma_teknologi_new.dc_layanan_pendaftaran(id_pendaftaran);

CREATE INDEX idx_lp_iddokter 
ON farma_teknologi_new.dc_layanan_pendaftaran(id_dokter);

CREATE INDEX idx_cbg_id 
ON farma_teknologi_new.cbg_status_klaim(id);

CREATE INDEX idx_pendaftaran_id 
ON farma_teknologi_new.dc_pendaftaran(id);

CREATE INDEX idx_pendaftaran_idpasien
ON farma_teknologi_new.dc_pendaftaran(id_pasien);

CREATE INDEX idx_cbg_code
ON farma_teknologi_new.cbg_status_klaim(cbg_code);

CREATE INDEX idx_cbg_status
ON farma_teknologi_new.cbg_status_klaim(status_klaim);

CREATE INDEX idx_cbg_waktu
ON farma_teknologi_new.cbg_status_klaim(waktu);

ALTER TABLE farma_teknologi_new.cbg_status_klaim 
ADD COLUMN tanggal DATE;

UPDATE farma_teknologi_new.cbg_status_klaim 
SET tanggal = DATE(waktu);

CREATE INDEX idx_cbg_tanggal
ON farma_teknologi_new.cbg_status_klaim(tanggal);

CREATE TEMPORARY TABLE tmp_dokter AS
SELECT id_pendaftaran, MIN(id_dokter) AS id_dokter
FROM farma_teknologi_new.dc_layanan_pendaftaran
GROUP BY id_pendaftaran;

CREATE INDEX idx_tmp_pendaftaran 
ON tmp_dokter(id_pendaftaran);

-- Insert Fact_klaim
INSERT INTO fact_klaim (
    pendaftaran_id,
    time_key,
    pasien_key,
    dokter_key,
    cbg_key,
    status_key,
    total_tagihan,
    total_klaim,
    margin,
    durasi_klaim_jam
)
SELECT
    d.id,
    dt.time_key,
    dp.pasien_key,
    dd.dokter_key,
    dc.cbg_key,
    ds.status_key,
    c.tagihan_rs,
    c.klaim,
    (c.tagihan_rs - c.klaim),
    TIMESTAMPDIFF(HOUR, c.waktu, c.waktu_update)
FROM farma_teknologi_new.dc_pendaftaran d
JOIN farma_teknologi_new.cbg_status_klaim c 
    ON c.id = d.id
JOIN tmp_dokter lp 
    ON lp.id_pendaftaran = d.id
JOIN dim_time dt 
    ON dt.tanggal = c.tanggal
JOIN dim_pasien dp 
    ON dp.id_pasien = d.id_pasien
JOIN dim_dokter dd 
    ON dd.id_dokter = lp.id_dokter
JOIN dim_cbg dc 
    ON dc.kode_cbg = c.cbg_code
JOIN dim_status_klaim ds 
    ON ds.status_klaim = c.status_klaim;

-- Create Fact Resep Detail
CREATE TABLE fact_resep_detail (
    fact_resep_id INT PRIMARY KEY AUTO_INCREMENT,
    pendaftaran_id INT,
    time_key INT,
    dokter_key INT,
    diagnosa_key INT,
    obat_key INT,
    qty_obat INT,

    FOREIGN KEY (time_key) REFERENCES dim_time(time_key),
    FOREIGN KEY (dokter_key) REFERENCES dim_dokter(dokter_key),
    FOREIGN KEY (diagnosa_key) REFERENCES dim_diagnosa(diagnosa_key),
    FOREIGN KEY (obat_key) REFERENCES dim_obat(obat_key)
);

-- OLTP
CREATE INDEX idx_dx_idlayanan 
ON farma_teknologi_new.dc_diagnosa(id_layanan_pendaftaran);

CREATE INDEX idx_r_idlayanan 
ON farma_teknologi_new.dc_resep_tebus(id_layanan_pendaftaran);

CREATE INDEX idx_rr_idresep 
ON farma_teknologi_new.dc_resep_tebus_r(id_resep_tebus);

CREATE INDEX idx_rd_idrr 
ON farma_teknologi_new.dc_resep_tebus_r_detail(id_resep_tebus_r);

-- DIM
CREATE INDEX idx_dim_diagnosa_kode ON dim_diagnosa(kode_penyakit);
CREATE INDEX idx_dim_dokter_id ON dim_dokter(id_dokter);

-- Insert fact_resep_detail 
INSERT INTO fact_resep_detail (
    pendaftaran_id,
    time_key,
    dokter_key,
    diagnosa_key,
    obat_key,
    qty_obat
)
SELECT
    dp.id AS pendaftaran_id,
    dt.time_key,
    dd.dokter_key,
    ddiag.diagnosa_key,
    dob.obat_key,
    SUM(rdet.jumlah_pakai) AS qty_obat
FROM farma_teknologi_new.dc_pendaftaran dp

JOIN farma_teknologi_new.dc_layanan_pendaftaran lp 
    ON lp.id_pendaftaran = dp.id

JOIN farma_teknologi_new.dc_resep_tebus rt 
    ON rt.id_layanan_pendaftaran = lp.id

JOIN farma_teknologi_new.dc_resep_tebus_r r 
    ON r.id_resep_tebus = rt.id

JOIN farma_teknologi_new.dc_resep_tebus_r_detail rdet 
    ON rdet.id_resep_tebus_r = r.id

-- DIM TIME
JOIN dim_time dt 
    ON dt.tanggal = DATE(rt.tanggal_resep)

-- DIM DOKTER
JOIN dim_dokter dd 
    ON dd.id_dokter = rt.id_dokter

-- DIAGNOSA
JOIN farma_teknologi_new.dc_diagnosa dx 
    ON dx.id_layanan_pendaftaran = lp.id

JOIN farma_teknologi_new.dc_golongan_sebab_sakit gs 
    ON gs.id = dx.id_golongan_sebab_sakit

JOIN dim_diagnosa ddiag
    ON ddiag.kode_penyakit = gs.no_daftar_terperinci

-- DIM OBAT
JOIN dim_obat dob 
    ON dob.nama_barang = rdet.nama_barang

WHERE dp.pakai_resep = 'ya'

GROUP BY
    dp.id,
    dt.time_key,
    dd.dokter_key,
    ddiag.diagnosa_key,
    dob.obat_key;