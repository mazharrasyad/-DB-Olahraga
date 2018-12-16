-- Database

-- createdb dbolahraga -U ti1
-- dropdb dbolahraga -U ti1
-- psql dbolahraga -U ti1

-- Create Table Min 6 + Inheritance

drop table if exists pengguna cascade;
create table pengguna(
id serial primary key,
nama varchar(50) not null,
no_hp varchar(13) not null unique,
email varchar(25) not null unique
);

drop table if exists pengelola cascade;
create table pengelola(
no_rek varchar(20) not null unique,
nama_gor varchar(20) not null,
alamat_gor text not null,
penghasilan double precision default 0,
total_booking int default 0,
primary key(id)
)inherits(pengguna);

drop table if exists history_pengelola cascade;
create table history_pengelola(
id serial primary key,
pengelola_id int references pengelola(id),
tgl_pinjam timestamp not null,
tgl_selesai timestamp not null,
pendapatan double precision not null
);

drop table if exists cabor cascade;
create table cabor(
id serial primary key,
nama varchar(20) not null,
harga_perjam double precision not null,
harga_perhari double precision not null
);

drop table if exists fasilitas cascade;
create table fasilitas(
id serial primary key,
pengelola_id int references pengelola(id),
cabor_id int references cabor(id)
);

drop table if exists peringkat cascade;
create table peringkat(
id serial primary key,
nama varchar(10) not null,
diskon double precision
);

drop table if exists penyewa cascade;
create table penyewa(
peringkat_id int references peringkat(id),
budget double precision,
primary key(id)
)inherits(pengguna);

drop table if exists history_penyewa cascade;
create table history_penyewa(
id serial primary key,
penyewa_id int references penyewa(id),
tgl_pinjam timestamp not null,
tgl_selesai timestamp not null,
biaya double precision not null
);

drop table if exists booking cascade;
create table booking(
id serial primary key,
penyewa_id int references penyewa(id),
tgl_book timestamp default current_timestamp
);

drop table if exists booking_detail cascade;
create table booking_detail(
booking_id int references booking(id),
fasilitas_id int references fasilitas(id),
tgl_pinjam timestamp not null,
tgl_selesai timestamp not null,
harga double precision default 0,
status varchar(10) default 'Pending'
);

-- Insert Table

insert into pengelola values
(default,'Ahmad','081290351971','ahmad@gmail.com','12345678901','GOR A','Depok',default,default),
(default,'Azhar','081290351972','azhar@gmail.com','12345678902','GOR B','Cibinong',default,default),
(default,'Rasyad','081290351973','rasyad@gmail.com','12345678903','GOR C','Citayam',default,default);

insert into cabor values
(1,'Basket',20000,100000),
(2,'Futsal',30000,150000),
(3,'Badminton',40000,200000);

insert into fasilitas values
(default,1,1),
(default,1,2),
(default,2,2),
(default,2,3),
(default,3,3),
(default,3,1);

insert into peringkat values
(1,'Perunggu',0.00),
(2,'Perak',0.05),
(3,'Emas',0.10);

insert into penyewa values
(default,'Rozzy','081290351974','rozzy@gmail.com',1,1000000),
(default,'Enricho','081290351975','enricho@gmail.com',1,2000000),
(default,'Alkalas','081290351976','alkalas@gmail.com',1,3000000);

-- Select Table

select * from pengguna;
select * from pengelola;
select * from history_pengelola;
select * from cabor;
select * from fasilitas;
select * from peringkat;
select * from penyewa;
select * from history_penyewa;
select * from peringkat;
select * from booking;
select * from booking_detail;

-- Procedure Min 4

-- Create Procedure

drop function if exists buat_booking(int, int, timestamp, timestamp) cascade;
create or replace function
buat_booking(int, int, timestamp, timestamp) 
returns text as
$$
	declare		
		v_penyewa_id alias for $1;
		v_fasilitas_id alias for $2;
		v_tgl_pinjam alias for $3;
		v_tgl_selesai alias for $4;
		v_id int;
		v_harga double precision;
		v_harga_perjam double precision;
		v_harga_perhari double precision;
		hari double precision;
		jam double precision;
		v2_penyewa_id int;
		v2_fasilitas_id int;		
	begin
		select into v_id id from booking order by id desc limit 1;
		select into v2_penyewa_id id from penyewa;
		select into v2_fasilitas_id id from fasilitas;
		select into v_harga_perjam harga_perjam from cabor where id = v_fasilitas_id;
		select into v_harga_perhari harga_perhari from cabor where id = v_fasilitas_id;
			
		hari = date_part('day', (v_tgl_selesai - v_tgl_pinjam));
		jam = date_part('hour', (v_tgl_selesai - v_tgl_pinjam));
	
		if hari = 0 then		
			v_harga = v_harga_perjam * jam;
		else
			v_harga = v_harga_perhari * hari;
		end if;			
		
		if v_id is null then
			v_id = 1;
		else
			v_id = v_id + 1;
		end if;				
	
		if v_penyewa_id = v2_penyewa_id then
			insert into booking values
			(v_id, v_penyewa_id, default);
		
			if v_fasilitas_id = v2_fasilitas_id then
				insert into booking_detail values
				(v_id, v_fasilitas_id, v_tgl_pinjam, v_tgl_selesai, v_harga, default);
				return 'Booking Berhasil';
			else
				raise exception 'ID Fasilitas Tidak Ada';
			end if;
		else
			raise exception 'ID Penyewa Tidak Ada';
		end if;					
	end
$$ language plpgsql;

-- Select Procedure
select buat_booking(1,1,timestamp '2019-12-01 08:00:00',timestamp '2019-12-01 10:00:00');
select buat_booking(4,4,timestamp '2019-12-01 08:00:00',timestamp '2019-12-01 10:00:00');
select buat_booking(4,1,timestamp '2019-12-01 08:00:00',timestamp '2019-12-01 10:00:00');
select buat_booking(5,3,timestamp '2019-12-01 00:00:00',timestamp '2019-12-03 00:00:00');
select * from booking;
select * from booking_detail;

-- Trigger Min 4 + 2 Otomatis
select id from penyewa limit 1 offset 3;
-- Transaction
