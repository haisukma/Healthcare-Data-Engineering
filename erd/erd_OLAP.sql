CREATE TABLE `dim_time` (
  `time_key` int PRIMARY KEY AUTO_INCREMENT,
  `tanggal` date,
  `bulan` int,
  `nama_bulan` varchar(20),
  `tahun` int,
  `kuartal` int
);

CREATE TABLE `dim_pasien` (
  `pasien_key` int PRIMARY KEY AUTO_INCREMENT,
  `id_pasien` int,
  `nama_pasien` varchar(100),
  `jenis_kelamin` varchar(20),
  `tanggal_lahir` date,
  `umur_saat_klaim` int,
  `kelompok_umur` varchar(20)
);

CREATE TABLE `dim_dokter` (
  `dokter_key` int PRIMARY KEY AUTO_INCREMENT,
  `id_dokter` int,
  `nama_dokter` varchar(100),
  `spesialisasi` varchar(100),
  `profesi` varchar(50),
  `status_pegawai` varchar(50)
);

CREATE TABLE `dim_diagnosa` (
  `diagnosa_key` int PRIMARY KEY AUTO_INCREMENT,
  `kode_penyakit` varchar(20),
  `nama_penyakit` varchar(200),
  `golongan` varchar(100),
  `menular` varchar(10),
  `kronis` varchar(50)
);

CREATE TABLE `dim_obat` (
  `obat_key` int PRIMARY KEY AUTO_INCREMENT,
  `nama_barang` varchar(200),
  `formularium` varchar(10),
  `kronis` varchar(10)
);

CREATE TABLE `dim_cbg` (
  `cbg_key` int PRIMARY KEY AUTO_INCREMENT,
  `kode_cbg` varchar(20),
  `deskripsi_cbg` varchar(200)
);

CREATE TABLE `dim_status_klaim` (
  `status_key` int PRIMARY KEY AUTO_INCREMENT,
  `status_klaim` varchar(50),
  `upload` varchar(20),
  `upload_doc` varchar(20)
);

CREATE TABLE `fact_klaim` (
  `fact_klaim_id` int PRIMARY KEY AUTO_INCREMENT,
  `pendaftaran_id` int,
  `time_key` int,
  `pasien_key` int,
  `dokter_key` int,
  `cbg_key` int,
  `status_key` int,
  `total_tagihan` decimal(18,2),
  `total_klaim` decimal(18,2),
  `margin` decimal(18,2),
  `durasi_klaim_jam` decimal(10,2),
  `jumlah_resep` int,
  `jumlah_obat` int,
  `jumlah_diagnosa` int
);

CREATE TABLE `fact_resep_detail` (
  `fact_resep_id` int PRIMARY KEY AUTO_INCREMENT,
  `pendaftaran_id` int,
  `time_key` int,
  `dokter_key` int,
  `diagnosa_key` int,
  `obat_key` int,
  `qty_obat` int
);

ALTER TABLE `fact_klaim` ADD FOREIGN KEY (`time_key`) REFERENCES `dim_time` (`time_key`);

ALTER TABLE `fact_klaim` ADD FOREIGN KEY (`pasien_key`) REFERENCES `dim_pasien` (`pasien_key`);

ALTER TABLE `fact_klaim` ADD FOREIGN KEY (`dokter_key`) REFERENCES `dim_dokter` (`dokter_key`);

ALTER TABLE `fact_klaim` ADD FOREIGN KEY (`cbg_key`) REFERENCES `dim_cbg` (`cbg_key`);

ALTER TABLE `fact_klaim` ADD FOREIGN KEY (`status_key`) REFERENCES `dim_status_klaim` (`status_key`);

ALTER TABLE `fact_resep_detail` ADD FOREIGN KEY (`time_key`) REFERENCES `dim_time` (`time_key`);

ALTER TABLE `fact_resep_detail` ADD FOREIGN KEY (`dokter_key`) REFERENCES `dim_dokter` (`dokter_key`);

ALTER TABLE `fact_resep_detail` ADD FOREIGN KEY (`diagnosa_key`) REFERENCES `dim_diagnosa` (`diagnosa_key`);

ALTER TABLE `fact_resep_detail` ADD FOREIGN KEY (`obat_key`) REFERENCES `dim_obat` (`obat_key`);
