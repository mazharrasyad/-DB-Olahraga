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

drop table if exists cabor cascade;
create table cabor(
id serial primary key,
nama varchar(20) not null
);

drop table if exists fasilitas cascade;
create table fasilitas(
id serial primary key,
pengelola_id int references pengelola(id),
cabor_id int references cabor(id),
harga_perjam double precision not null,
harga_perhari double precision not null
);

drop table if exists member cascade;
create table member(
id serial primary key,
nama varchar(10) not null,
diskon double precision
);

drop table if exists penyewa cascade;
create table penyewa(
member_id int references member(id),
budget double precision,
primary key(id)
)inherits(pengguna);

drop table if exists booking cascade;
create table booking(
id serial primary key,
penyewa_id int references penyewa(id),
tgl_book timestamp default current_timestamp
);

drop table if exists history_penyewa cascade;
create table history_penyewa(
id serial primary key,
penyewa_id int references penyewa(id),
booking_id int references booking(id),
member_id int references member(id),
biaya double precision not null
);

drop table if exists history_pengelola cascade;
create table history_pengelola(
id serial primary key,
pengelola_id int references pengelola(id),
booking_id int references booking(id),
pendapatan double precision not null
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
(1,'Basket'),
(2,'Futsal'),
(3,'Badminton');

insert into fasilitas values
(default,1,1,10000,100000),
(default,1,2,20000,150000),
(default,2,2,30000,200000),
(default,2,3,40000,250000),
(default,3,3,50000,300000),
(default,3,1,60000,350000);

insert into member values
(1,'Perunggu',0.00),
(2,'Perak',0.05),
(3,'Emas',0.10);

insert into penyewa values
(default,'Rozzy','081290351974','rozzy@gmail.com',1,1000000),
(default,'Enricho','081290351975','enricho@gmail.com',2,2000000),
(default,'Alkalas','081290351976','alkalas@gmail.com',2,3000000);

-- Select Table

select * from pengguna;
select * from pengelola;
select * from history_pengelola;
select * from cabor;
select * from fasilitas;
select * from member;
select * from penyewa;
select * from history_penyewa;
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
		i int;
		pesan text;
	begin
		select into v_id id from booking order by id desc limit 1;		
		select into v_harga_perjam harga_perjam from fasilitas where id = v_fasilitas_id;
		select into v_harga_perhari harga_perhari from fasilitas where id = v_fasilitas_id;				
	
		if date_part('day', (v_tgl_selesai - v_tgl_pinjam)) = 0 then
			jam = date_part('hour', (v_tgl_selesai - v_tgl_pinjam));			
			v_harga = v_harga_perjam * jam;
			pesan = jam || ' Jam';
		else
			hari = date_part('day', (v_tgl_selesai - v_tgl_pinjam));
			hari = hari + 1;
			v_harga = v_harga_perhari * hari;
			pesan = hari || ' Hari';
		end if;			
		
		if v_id is null then
			v_id = 1;
		else
			v_id = v_id + 1;
		end if;	

		i = 0;
		loop
			select into v2_penyewa_id id from penyewa limit 1 offset i;						
			
			if v_penyewa_id = v2_penyewa_id then				
				exit;	
			elseif v2_penyewa_id is null then
				exit;
			end if;			
			
			i = i + 1;				
		end loop;		
	
		i = 0;
		loop
			select into v2_fasilitas_id id from fasilitas limit 1 offset i;						
			
			if v_fasilitas_id = v2_fasilitas_id then				
				exit;	
			elseif v2_fasilitas_id is null then
				exit;
			end if;			
			
			i = i + 1;				
		end loop;	

		if v_penyewa_id = v2_penyewa_id then
			insert into booking values
			(v_id, v_penyewa_id, default);
		
			if v_fasilitas_id = v2_fasilitas_id then
				insert into booking_detail values
				(v_id, v_fasilitas_id, v_tgl_pinjam, v_tgl_selesai, v_harga, default);
				return 'Booking Berhasil Selama ' || pesan;
			else
				raise exception 'ID Fasilitas Tidak Ada';
			end if;
		else
			raise exception 'ID Penyewa Tidak Ada';
		end if;	
	end
$$ language plpgsql;

-- Development
drop function if exists trasnfer(int, varchar) cascade;
create or replace function
transfer(int, varchar) 
returns text as
$$
	declare	
		v_booking_id alias for $1;
		v_no_rek alias for $2;
		v_harga double precision;
		v_status text;
		v_penyewa_id int;
		v_budget int;
		v_pengelola_id int;
		v_fasilitas_id int;
		v_member_id int;
		v_diskon double precision;
		v2_booking_id int;
		v2_no_rek text;
		v2_pengelola_id int;
		v2_diskon double precision;
		i int;
	begin			
		select into v_status status from booking_detail where booking_id = v_booking_id;
		select into v_harga harga from booking_detail where booking_id = v_booking_id;		
		select into v_penyewa_id penyewa_id from booking where id = v_booking_id;
		select into v_budget budget from penyewa where id = v_penyewa_id;
		select into v_pengelola_id id from pengelola where no_rek = v_no_rek;
		select into v_fasilitas_id fasilitas_id from booking_detail where booking_id = v_booking_id;
		select into v2_pengelola_id pengelola_id from fasilitas where id = v_fasilitas_id;
		select into v_member_id member_id from penyewa where id = v_penyewa_id;
		select into v_diskon diskon from member where id = v_member_id;
				
		i = 0;
		loop
			select into v2_booking_id booking_id from booking_detail limit 1 offset i;			
			
			if v_booking_id = v2_booking_id then				
				exit;	
			elseif v2_booking_id is null then
				exit;
			end if;			
			
			i = i + 1;				
		end loop;	
	
		i = 0;
		loop
			select into v2_no_rek no_rek from pengelola limit 1 offset i;			
			
			if v_no_rek = v2_no_rek then				
				exit;	
			elseif v2_no_rek is null then
				exit;
			end if;			
			
			i = i + 1;				
		end loop;	

		if v_booking_id = v2_booking_id then
			if v_no_rek = v2_no_rek then
				if v_pengelola_id = v2_pengelola_id then
					if v_status = 'Pending' then
						if v_harga <= v_budget then						
							update penyewa set budget = budget - v_harga
							where id = v_penyewa_id;
						
							update pengelola set penghasilan = penghasilan + v_harga
							where id = v_pengelola_id;
						
							update booking_detail set status = 'Berhasil'
							where booking_id = v_booking_id;

							v2_diskon = v_harga * v_diskon;
						
							update penyewa set budget = budget + v2_diskon
							where id = v_penyewa_id;
						
							insert into history_penyewa values
							(default, v_penyewa_id, v_booking_id, v_member_id, v_harga - v2_diskon);
						
							insert into history_pengelola values
							(default, v_pengelola_id, v_booking_id, v_harga);
						
							return 'Transfer Berhasil';
						else
							raise exception 'Budget Tidak Mencukupi';
						end if;
					else
						raise exception 'ID Booking Tidak Berlaku';
					end if;	
				else
					raise exception 'No Rekening Salah Kirim';
				end if;
			else
				raise exception 'No Rekening Tidak Ada';
			end if;
		else
			raise exception 'ID Booking Tidak Ada';
		end if;	
	end
$$ language plpgsql;

drop function if exists tingkat_member() cascade;
create or replace function 
tingkat_member() returns trigger as
$$
	declare
		v_biaya double precision;
	begin		
		select into v_biaya sum(biaya) from history_penyewa where penyewa_id = new.penyewa_id;			
	
		if 1000000 < v_biaya then
			update penyewa set member_id = '3' where id = new.penyewa_id;
		elseif 500000 < v_biaya then
			update penyewa set member_id = '2' where id = new.penyewa_id;
		end if;
		
		return new;
	end
$$ language plpgsql;

drop function if exists batal_booking() cascade; 
create or replace function 
batal_booking(int) returns text as
$$
	declare
		v_booking_id alias for $1;
		v2_booking_id int;
		v_status text;
		i int;
	begin
		i = 0;
		loop
			select into v2_booking_id booking_id from booking_detail limit 1 offset i;			
			
			if v_booking_id = v2_booking_id then				
				exit;	
			elseif v2_booking_id is null then
				exit;
			end if;			
			
			i = i + 1;				
		end loop;
		
		if v_booking_id = v2_booking_id then
			select into v_status status from booking_detail where booking_id = v_booking_id;
		
			if v_status = 'Pending' then
				delete from booking_detail where booking_id = v_booking_id;
				return 'Booking Berhasil Dibatalkan';
			else
				raise exception 'Status Booking Bukan Pending';
			end if;
		else
			raise exception 'ID Booking Tidak Ada';
		end if;
	end
$$ language plpgsql;

drop function if exists proses_batal_booking() cascade;
create or replace function 
proses_batal_booking() returns trigger as
$$
	begin
		delete from booking 
		where id = old.booking_id;
		return old;
	end
$$ language plpgsql;

-- Batas waktu transfer

-- Trigger Min 4 + 2 Otomatis

drop trigger trig_tingkat_member on history_penyewa;
create trigger trig_tingkat_member after
insert on history_penyewa for each row
execute procedure tingkat_member();

drop trigger trig_proses_batal_booking on booking_detail;
create trigger trig_proses_batal_booking after
delete on booking_detail for each row
execute procedure proses_batal_booking();

-- Select Procedure
select * from penyewa;
select * from fasilitas;
select buat_booking(1,1,timestamp '2019-12-01 08:00:00',timestamp '2019-12-01 10:00:00');
select buat_booking(4,7,timestamp '2019-12-01 08:00:00',timestamp '2019-12-01 10:00:00');
select buat_booking(4,1,timestamp '2019-12-01 08:00:00',timestamp '2019-12-01 10:00:00');
select buat_booking(6,6,timestamp '2019-12-01 00:00:00',timestamp '2019-12-04 00:00:00');
select * from booking;
select * from booking_detail;

select * from penyewa;
select * from pengelola;
select * from booking_detail;
select transfer(3,'12345678901');
select transfer(1,'12345678001');
select transfer(2,'12345678901');
select transfer(2,'12345678903');
select * from history_penyewa;
select * from history_pengelola;
 
select * from booking;
select * from booking_detail;
select batal_booking(1);

-- Transaction

begin
	
end