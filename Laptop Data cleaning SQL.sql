Use db;


# Take Data backup
create table laptop_backup like laptopdata;
insert into laptop_backup
select * from laptopdata;




# check storage size
# byte/1024 = KB
select Data_length/1024 from information_schema.Tables
where Table_schema = 'db' and Table_name = 'laptopdata';



# change column name unnamed: 0  to index
ALTER TABLE laptopdata RENAME COLUMN `Unnamed: 0` TO `index`;



# check for null values
select * 
from laptopdata l
where Company is null or TypeName is null or Inches is null or ScreenResolution is null 
or Cpu is null or Ram is null or Memory is null or Gpu is null or OpSys is null
or Weight is null or Price is null or l.index is null;



# DEAL WITH DUPLICATES
# distinct index
select count(distinct(l.index)) from laptopdata l;

# delete duplicates
delete from laptopdata l
where l.index in (
select t.index from (select l.index,Company, TypeName, Inches, ScreenResolution,
							Cpu, Ram, Memory, Gpu, OpSys, Weight, Price,
							row_number() over(partition by Company, TypeName, Inches, 
                            ScreenResolution,Cpu, Ram, Memory, Gpu, OpSys, Weight, Price) r
                            from laptopdata l) t
where r > 1);

# check duplicates 
select t.index from (select l.index,Company, TypeName, Inches, ScreenResolution,
							Cpu, Ram, Memory, Gpu, OpSys, Weight, Price,
							row_number() over(partition by Company, TypeName, Inches, 
                            ScreenResolution,Cpu, Ram, Memory, Gpu, OpSys, Weight, Price) r
                            from laptop l) t
where r > 1;



# Fix RAm column
select distinct(Ram) from laptopData;

update laptopdata
set Ram = replace(Ram,'GB','');

alter table laptopdata modify column ram integer;



# Fix weight column
select distinct(weight) from laptopdata;

update laptopdata
set weight = replace(weight,'kg','');

# non numeric value '?'
SELECT * FROM laptopdata WHERE weight NOT REGEXP '^[0-9.]+$';

update laptopdata
set weight = replace(weight,'?','0');

ALTER TABLE laptopdata MODIFY COLUMN weight decimal(10,3);



# FIX PRICE COLUMN
update laptopdata
set Price = round(price);

alter table laptopdata modify column price integer;



# FIX OpSys column
select distinct(OpSys) from laptopdata;

Update laptopdata
SET OpSys =  case
				when opsys like '%mac%' then 'macos'
				when opsys like '%Windows%' then 'windows'
				when opsys like '%Linux%' then 'linux'
				when opsys like '%Chrome%' then 'chromeOS'
				when opsys like '%Android%' then 'androidOS'
				when opsys like '$No OS%' then 'n/a'
			end;



# FIX GPU COLUMN
Alter table laptopdata
add column Gpu_brand varchar(255) AFTER Gpu,
add column Gpu_name varchar(255) AFTER Gpu_brand;

Update laptopdata
set Gpu_brand = substring_index(Gpu,' ',1);

Update laptopdata
set Gpu_name = replace(Gpu,Gpu_brand,'');

alter table laptopdata drop column Gpu;



# FIX CPU column
Alter table laptopdata
add column Cpu_brand varchar(255) AFTER Cpu,
add column Cpu_name varchar(255) AFTER Cpu_brand,
add column Cpu_speed varchar(255) AFTER Cpu_model;

update laptopdata
set Cpu_brand = substring_index(Cpu,' ',1);
update laptopdata
set Cpu_name = substring_index(replace(Cpu,Cpu_brand, ''),Cpu_speed,1);
update laptopdata
set Cpu_speed = replace(substring_index(Cpu,' ',-1), 'GHz', '');

alter table laptopdata drop column cpu;



# Clean ScreenResolution column
alter table laptopdata
add column Resolution_width integer after ScreenResolution,
add column Resolution_height integer after Resolution_width,
add column Touch_screen integer after Resolution_height;

Update laptopdata
set Resolution_width = substring_index(substring_index(ScreenResolution, ' ',-1),'x',1);
Update laptopdata
set Resolution_height = substring_index(substring_index(ScreenResolution, ' ',-1),'x',-1);
Update laptopdata
set Touch_screen = Case when ScreenResolution like '%Touchscreen%' then 1 else 0 end;

alter table laptopdata drop column ScreenResolution;



# Clean memeory column
alter table laptopdata
add column memory_type varchar(255) after memory,
add column primary_storage integer after memory_type,
add column secondary_storage integer after primary_storage;

Update laptopdata
set memory_type = Case
					when Memory like '%SSD%' and Memory like '%HDD%' then 'Hybrid'
					when Memory like '%SSD%' then 'SSD'
					when Memory like '%HDD%' then 'HDD'
					when Memory like '%Flash%' then 'Flash'
					else null
				  End;
Update laptopdata
set primary_storage = regexp_substr(substring_index(memory,'+',1), '[0-9]+');
Update laptopdata
set secondary_storage = case
							when memory like '%+%' then REGEXP_substr(substring_index(memory,'+',-1), '[0-9]+') else 0
						end;
Update laptopdata
set secondary_storage = case
							when secondary_storage <=2 then secondary_storage*1024 else secondary_storage
						end;

alter table laptopdata drop column memory;
select * from laptopdata;


# remove generation of cpu_name due to too many category
Update laptopdata
set Cpu_name = substring_index(cpu_name, ' ',3);


