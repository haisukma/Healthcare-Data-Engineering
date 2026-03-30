CREATE TABLE `dc_pasien` (
  `id` int PRIMARY KEY,
  `tanggal_daftar` datetime,
  `nama` varchar(100),
  `kelamin` enum(L,P),
  `tanggal_lahir` date,
  `agama` enum(Islam,Kristen,Katholik,Hindu,Budha,Lain-lain),
  `gol_darah` enum(A,B,AB,O,Unknown),
  `status_pernikahan` enum(Belum Menikah,Menikah,Janda,Duda),
  `alergi` text,
  `status` enum(Hidup,Meninggal),
  `is_kronis` enum(Ya,Tidak,Tidak Diketahui)
);

CREATE TABLE `dc_pegawai` (
  `id` int PRIMARY KEY,
  `nama` varchar(50),
  `kelamin` enum(L,P),
  `agama` enum(Islam,Kristen,Katholik,Hindu,Budha,Lain-lain),
  `active` enum(1,0,2),
  `status_pegawai` enum(Pegawai,Non Pegawai)
);

CREATE TABLE `dc_nakes` (
  `id` int PRIMARY KEY,
  `id_pegawai` int,
  `kode_spesialisasi` varchar(10),
  `nama_spesialisasi` varchar(100),
  `tgl_mulai_praktek` date,
  `nama_profesi` varchar(50)
);

CREATE TABLE `dc_pendaftaran` (
  `id` int PRIMARY KEY,
  `no_register` varchar(15),
  `id_pasien` int,
  `waktu_daftar` datetime,
  `waktu_keluar` datetime,
  `jenis` enum(Poliklinik,Igd,Rawat Inap,MCU,Laboratorium,Radiologi,Fisioterapi,Forensik,Hemodialisa,Kemoterapi,Bayi,Psikometri),
  `rawat` enum(Jalan,Inap),
  `jenis_igd` enum(Umum,Kamar Bersalin,Hemodialisa,Kemoterapi,Ponek,Visum,Bedah,Anak,Kebidanan,Maternal,Bayi,Non Bedah,Psikiatrik,Geriatri),
  `kondisi_keluar` enum(Hidup,Meninggal),
  `status` enum(Baru,Lama,Batal,Booking),
  `keluar_rs` int,
  `pakai_resep` enum(Ya,Tidak)
);

CREATE TABLE `dc_layanan_pendaftaran` (
  `id` int PRIMARY KEY,
  `id_pendaftaran` int,
  `waktu` datetime,
  `waktu_periksa` datetime,
  `waktu_status_keluar` datetime,
  `id_dokter` int,
  `jenis` enum(Poliklinik,Igd,Rawat Inap,MCU,Laboratorium,Radiologi,Fisioterapi,Forensik,Hemodialisa,Kemoterapi,Bayi,Psikometri),
  `kondisi` enum(Hidup,Meninggal),
  `cara_bayar` enum(Tunai,Asuransi,Perusahaan,Karyawan,Charity,Integrasi),
  `terklaim` enum(0,1),
  `status` enum(Belum,Sedang,Sudah,Batal),
  `tindak_lanjut` enum(Pulang APS,Klinik Lain,RS Lain,Pulang,IGD,Perujuk,Rawat Inap,Forensik,Lain-lain,Batal),
  `triase_primer` int,
  `jenis_lab` enum(Laboratorium PCR,Laboratorium Klinik,Laboratorium PA,Bank Darah,Mikrobiologi),
  `valid_time` tinyint(1),
  `Corrected_status_time` tinyint(1)
);

CREATE TABLE `dc_diagnosa` (
  `id` int PRIMARY KEY,
  `id_layanan_pendaftaran` int,
  `waktu` datetime,
  `id_dokter` int,
  `id_golongan_sebab_sakit` int,
  `kasus` enum(Lama,Baru),
  `Id_users` int,
  `primer` int,
  `kronis_farmasi` int
);

CREATE TABLE `dc_golongan_sebab_sakit` (
  `id` int PRIMARY KEY,
  `no_daftar_terperinci` char(20),
  `nama` varchar(255),
  `alias` varchar(255),
  `menular` enum(Tidak,Ya),
  `is_kronis` enum(Ya,Tidak,Tidak Diketahui),
  `status` tinyint,
  `versi` enum(Old,New),
  `checked` tnyint
);

CREATE TABLE `dc_resep_tebus` (
  `id` int PRIMARY KEY,
  `tanggal_resep` datetime,
  `id_dokter` int,
  `id_pasien` int,
  `id_layanan_pendaftaran` int,
  `status_obat_pulang` enum(Ya,Tidak,Tidak Diketahui),
  `jenis_resep` enum(Racikan,Non Racikan,Lain-lain),
  `asal_resep` varchar(255),
  `Valid_detail` tinyint(1)
);

CREATE TABLE `dc_resep_tebus_r` (
  `id` int PRIMARY KEY,
  `id_resep_tebus` int,
  `r_no` smallint,
  `resep_r_jumlah` decimal(5,2),
  `aturan_pakai` varchar(100),
  `ket_aturan_pakai` text,
  `timing` enum(Sebelum,Sesudah,Saat,Tidak Diketahui),
  `pemberian` enum(Pagi,Siang,Sore,Malam,Tidak Diketahui),
  `jam` datetime
);

CREATE TABLE `dc_resep_tebus_r_detail` (
  `id` int PRIMARY KEY,
  `id_resep_tebus_r` int,
  `jual_harga` double,
  `dosis_racik` double,
  `jumlah_pakai` double,
  `formulir` enum(Tidak,Ya),
  `kronis` tinyint,
  `nama_barang` varchar(100)
);

CREATE TABLE `cbg_status_klaim` (
  `id` int PRIMARY KEY,
  `waktu` datetime,
  `waktu_update` datetime,
  `waktu_final` datetime,
  `waktu_sent` datetime,
  `notifikasi` tinyint,
  `cbg_code` varchar(20),
  `status_klaim` enum(Not Yet,Added,Saved,Grouper Stage 1,Grouper Stage 2,Final),
  `status_klaim_idrg` enum(add_claim,set_claim,grouping_idrg_fail,grouping_idrg_success,final_idrg,grouping_inacbg_1_fail,grouping_inacbg_1_success,grouping_inacbg_2,final_inacbg,final_claim,send_claim),
  `upload` enum(Not Yet,Uploaded,Deleted),
  `tagihan_rs` double,
  `klaim` double,
  `upload_doc` enum(tidak ada,prepared,uploaded)
);

ALTER TABLE `dc_pendaftaran` ADD FOREIGN KEY (`id_pasien`) REFERENCES `dc_pasien` (`id`);

ALTER TABLE `dc_layanan_pendaftaran` ADD FOREIGN KEY (`id_pendaftaran`) REFERENCES `dc_pendaftaran` (`id`);

ALTER TABLE `dc_layanan_pendaftaran` ADD FOREIGN KEY (`id_dokter`) REFERENCES `dc_nakes` (`id`);

ALTER TABLE `dc_diagnosa` ADD FOREIGN KEY (`id_layanan_pendaftaran`) REFERENCES `dc_layanan_pendaftaran` (`id`);

ALTER TABLE `dc_diagnosa` ADD FOREIGN KEY (`id_golongan_sebab_sakit`) REFERENCES `dc_golongan_sebab_sakit` (`id`);

ALTER TABLE `dc_resep_tebus` ADD FOREIGN KEY (`id_layanan_pendaftaran`) REFERENCES `dc_layanan_pendaftaran` (`id`);

ALTER TABLE `dc_resep_tebus_r` ADD FOREIGN KEY (`id_resep_tebus`) REFERENCES `dc_resep_tebus` (`id`);

ALTER TABLE `dc_resep_tebus_r_detail` ADD FOREIGN KEY (`id_resep_tebus_r`) REFERENCES `dc_resep_tebus_r` (`id`);

ALTER TABLE `cbg_status_klaim` ADD FOREIGN KEY (`id`) REFERENCES `dc_pendaftaran` (`id`);

ALTER TABLE `dc_diagnosa` ADD FOREIGN KEY (`id_dokter`) REFERENCES `dc_nakes` (`id`);

ALTER TABLE `dc_resep_tebus` ADD FOREIGN KEY (`id_dokter`) REFERENCES `dc_nakes` (`id`);
