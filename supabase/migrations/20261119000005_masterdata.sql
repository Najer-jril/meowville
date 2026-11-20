-- 005_master_data.sql

insert into public.room_types (name, prefix, description, price, unit_count, facilities, packages, photo, active) values
  ('Standard', 'S',
   'Kamar nyaman untuk satu kucing dengan kasur empuk dan rak panjat kecil.',
   50000, 4, '{AC,"Kasur empuk"}', '{Mainan,"Laporan harian"}',
   'assets/images/rooms/standar.jpg', true),
  ('Deluxe', 'D',
   'Kamar luas dan sejuk khusus anabul aktif dengan area vertikal yang nyaman.',
   85000, 3, '{AC,"Jendela besar","Panjat kucing"}', '{Mainan,"Laporan harian","Sisir bulu"}',
   'assets/images/rooms/deluxe.png', true),
  ('Suite', 'ST',
   'Suite dengan jendela taman, cat tree tinggi, dan ruang bermain pribadi.',
   130000, 2, '{AC,"Jendela taman","Cat tree",CCTV}', '{Mainan,"Laporan harian","Sisir bulu","Foto harian"}',
   'assets/images/rooms/suite.png', true),
  ('Presidential', 'P',
   'Kamar terbesar dengan webcam 24 jam untuk dipantau pemilik.',
   200000, 1, '{AC,Webcam,"Ruang bermain"}', '{Mainan,"Laporan harian","Webcam 24h"}',
   'assets/images/rooms/presidential.png', false);

insert into public.addons (name, description, price, active) values
  ('Grooming Lengkap', 'Mandi, sisir, potongin kuku, bersihin telinga', 80000, true),
  ('Mandi Jamur', 'Perawatan khusus untuk masalah jamur kulit', 45000, true),
  ('Potong Kuku', 'Potong dan rapikan kuku', 25000, true),
  ('Antar Jemput', 'Jemput dan antar kucing ke rumah', 60000, true),
  ('Sisir Bulu', 'Sisir dan rapikan bulu', 20000, true),
  ('Catnip Aromaterapi', 'Pijat dan aromaterapi untuk relaksasi', 90000, false);
