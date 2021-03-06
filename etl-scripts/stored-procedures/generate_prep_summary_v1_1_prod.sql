CREATE PROCEDURE `generate_prep_summary_v1_1_prod`(IN query_type varchar(50), IN queue_number int, IN queue_size int, IN cycle_size int , IN log boolean)
BEGIN

					select @start := now();
					select @table_version := "flat_prep_summary_v1_1";
                    set @primary_table := "flat_prep_summary_v1_1";
                    set @query_type = query_type;
                    
                    set @total_rows_written = 0;
                    
					set session sort_buffer_size=512000000;

					select @sep := " ## ";
					select @last_date_created := (select max(max_date_created) from etl.flat_obs);

					CREATE TABLE IF NOT EXISTS `flat_prep_summary_v1_1` (
					  `date_created` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
					  `prev_id` bigint(20) DEFAULT NULL,
					  `cur_id` int(11) DEFAULT NULL,
					  `person_id` int(11) DEFAULT NULL,
					  `uuid` char(38) CHARACTER SET utf8 NOT NULL,
					  `visit_id` int(11) DEFAULT NULL,
					  `encounter_id` int(11) NOT NULL DEFAULT '0',
					  `encounter_datetime` datetime DEFAULT NULL,
					  `encounter_type` int(11) DEFAULT NULL,
					  `is_prep_clinical_encounter` int(0) DEFAULT NULL,
					  `enrollment_date` longtext CHARACTER SET utf8,
					  `prev_discontinued_prep` varchar(20) CHARACTER SET utf8 DEFAULT NULL,
					  `discontinued_prep` varchar(20) CHARACTER SET utf8 DEFAULT NULL,
					  `discontinued_prep_date` varchar(10) CHARACTER SET utf8 DEFAULT NULL,
                      `turned_positive` varchar(20) CHARACTER SET utf8 DEFAULT NULL,
					  `turned_positive_date` varchar(10) CHARACTER SET utf8 DEFAULT NULL,
					  `enrollment_location_id` varchar(20) CHARACTER SET utf8 DEFAULT NULL,
					  `location_id` bigint(60) DEFAULT NULL,
					  `prev_rtc_date` longtext,
					  `rtc_date` varchar(10) CHARACTER SET utf8 DEFAULT NULL,
					  `death_date` longtext CHARACTER SET utf8,
					  `prev_prep_meds` longtext,
					  `cur_prep_meds` longtext,
					  `first_prep_regimen` longtext,
					  `prep_start_date` varbinary(10) DEFAULT NULL,
					  `inital_prep_start_date` longblob,
					  `cur_prep_meds_names` text,
					  `first_prep_regimen_names` text,
					  `birthdate` date DEFAULT NULL,
					  `gender` varchar(50) CHARACTER SET utf8 DEFAULT '',
					  PRIMARY KEY (`encounter_id`),
					  KEY `person_date` (`person_id`,`encounter_datetime`),
					  KEY `location_rtc` (`location_id`,`rtc_date`),
					  KEY `person_uuid` (`uuid`),
                      KEY `person_id` (`person_id`),
					  KEY `location_enc_date` (`location_id`,`encounter_datetime`),
					  KEY `enc_date_location` (`encounter_datetime`,`location_id`)
					) ENGINE=InnoDB DEFAULT CHARSET=latin1;
                    
                    CREATE TABLE IF NOT EXISTS `prep_weekly_report_dataset_v1_1` (
					  `elastic_id` varchar(21) NOT NULL DEFAULT '',
					  `location_id` bigint(60) DEFAULT NULL,
					  `person_id` int(11) DEFAULT NULL,
					  `person_uuid` char(38) CHARACTER SET utf8 NOT NULL,
					  `birthdate` date DEFAULT NULL,
					  `death_date` longtext CHARACTER SET utf8,
					  `age` decimal(23,2) DEFAULT NULL,
					  `gender` varchar(50) CHARACTER SET utf8 DEFAULT '',
					  `encounter_id` int(11) NOT NULL DEFAULT '0',
					  `encounter_datetime` datetime DEFAULT NULL,
					  `encounter_week` int(6) DEFAULT NULL,
					  `week` varchar(10) NOT NULL DEFAULT '',
					  `prev_rtc_date` longtext,
					  `prev_rtc_week` int(6) DEFAULT NULL,
					  `rtc_date` varchar(10) CHARACTER SET utf8 DEFAULT NULL,
					  `rtc_week` int(6) DEFAULT NULL,
					  `cur_prep_meds_names` text,
					  `first_prep_regimen` longtext,
					  `prep_start_date` varbinary(10) DEFAULT NULL,
					  `visit_this_week` int(3) DEFAULT NULL,
					  `appointment_this_week` int(3) DEFAULT NULL,
					  `scheduled_visit_this_week` int(1) NOT NULL DEFAULT '0',
					  `early_appointment_this_week` int(1) NOT NULL DEFAULT '0',
					  `late_appointment_this_week` int(1) NOT NULL DEFAULT '0',
					  `missed_appointment_this_week` int(1) NOT NULL DEFAULT '0',
					  `weeks_since_rtc` varchar(23) CHARACTER SET utf8 DEFAULT NULL,
					  `status` varchar(12) CHARACTER SET utf8 DEFAULT NULL,
					  `active_on_prep_this_week` int(1) NOT NULL DEFAULT '0',
					  `prep_defaulter_this_week` int(1) NOT NULL DEFAULT '0',
					  `prep_ltfu_this_week` int(1) NOT NULL DEFAULT '0',
					  `prep_discontinued_this_week` int(1) NOT NULL DEFAULT '0',
					  `enrolled_in_prep_this_week` int(1) NOT NULL DEFAULT '0',
					  `discontinued_from_prep_this_week` int(1) NOT NULL DEFAULT '0',
                      `turned_positive_this_week` int(1) NOT NULL DEFAULT '0',
					 `prev_on_prep_and_turned_positive` int(1) NOT NULL DEFAULT '0',
					  PRIMARY KEY (`elastic_id`),
					  KEY `person_id` (`person_id`),
					  KEY `person_id_2` (`person_id`,`week`),
					  KEY `week` (`week`),
					  KEY `location_id` (`location_id`,`week`),
					  KEY `encounter_datetime` (`encounter_datetime`)
					) ENGINE=InnoDB DEFAULT CHARSET=latin1;

	
                    if(@query_type="build") then
                            select 'BUILDING..........................................';
                            set @write_table = concat("flat_prep_summary_temp_",queue_number);
                            set @queue_table = concat("flat_prep_summary_build_queue_",queue_number);                                                                    

                            SET @dyn_sql=CONCAT('Create table if not exists ',@write_table,' like ',@primary_table);
                            PREPARE s1 from @dyn_sql; 
                            EXECUTE s1; 
                            DEALLOCATE PREPARE s1;  

                            SET @dyn_sql=CONCAT('drop table if exists ',@queue_table,';'); 
                            PREPARE s1 from @dyn_sql; 
                            EXECUTE s1; 
                            DEALLOCATE PREPARE s1; 
                            
                            SET @dyn_sql=CONCAT('Create table if not exists ',@queue_table,' (select patient_id as person_id from flat_prep_summary_build_queue limit ', queue_size, ');'); 
                            PREPARE s1 from @dyn_sql; 
                            EXECUTE s1; 
                            DEALLOCATE PREPARE s1;  
                            
                            SET @dyn_sql=CONCAT('delete t1 from flat_prep_summary_build_queue t1 join ',@queue_table, ' t2 on (person_id = patient_id);'); 
                            PREPARE s1 from @dyn_sql; 
							EXECUTE s1; 
							DEALLOCATE PREPARE s1;  

                    end if;
    
                    
                    if (@query_type="sync") then
                            select 'SYNCING..........................................';
                            set @write_table = "flat_prep_summary";
                            set @queue_table = "flat_prep_summary_sync_queue";
                            create table if not exists flat_prep_summary_sync_queue (person_id int primary key);                            
                            


                            set @last_update = null;
                            select max(date_updated) into @last_update from flat_log where table_name=@table_version;

                            replace into flat_prep_summary_sync_queue
                            (select distinct patient_id
                                from amrs.encounter
                                where date_changed > @last_update
                            );

                            replace into flat_prep_summary_sync_queue
                            (select distinct person_id
                                from etl.flat_obs
                                where max_date_created > @last_update
                            );

                            
                            replace into flat_prep_summary_sync_queue
                            (select person_id from 
                                amrs.person 
                                where date_voided > @last_update);


                            replace into flat_prep_summary_sync_queue
                            (select person_id from 
                                amrs.person 
                                where date_changed > @last_update);
                                

                      end if;
                      
					select @queue_table;
                    select @primary_table;
                    select @write_table;
                      
-- 					SET @dyn_sql=CONCAT('delete t1 FROM ',@queue_table,' t1
--                             join amrs.person_attribute t2 using (person_id)
--                             where t2.person_attribute_type_id=28 and value="true" and voided=0');
--                     PREPARE s1 from @dyn_sql; 
--                     EXECUTE s1; 
--                     DEALLOCATE PREPARE s1;  
					
                    SET @dyn_sql=CONCAT('select count(*) as queue_size from ',@queue_table); 
                    PREPARE s1 from @dyn_sql; 
                    EXECUTE s1; 
                    DEALLOCATE PREPARE s1; 

                    SET @person_ids_count = 0;
                    SET @dyn_sql=CONCAT('select count(*) into @person_ids_count from ',@queue_table); 
                    PREPARE s1 from @dyn_sql; 
                    EXECUTE s1; 
                    DEALLOCATE PREPARE s1;  

                    select @person_ids_count as 'num patients to sync';
                    
                    
                    SET @dyn_sql=CONCAT('delete t1 from ',@primary_table, ' t1 join ',@queue_table,' t2 using (person_id);'); 
                    PREPARE s1 from @dyn_sql; 
                    EXECUTE s1; 
                    DEALLOCATE PREPARE s1;  

                    set @total_time=0;
                    set @cycle_number = 0;


					while @person_ids_count > 0 do
                    
                        set @loop_start_time = now();
                        
                        
                        drop temporary table if exists flat_prep_summary_temp_queue;
                        SET @dyn_sql=CONCAT('create temporary table flat_prep_summary_temp_queue (person_id int primary key) (select * from ',@queue_table,' limit ',cycle_size,');'); 
                        PREPARE s1 from @dyn_sql; 
                        EXECUTE s1; 
                        DEALLOCATE PREPARE s1;
                        
                        drop temporary table if exists prep_patients_temp_queue;
						create temporary table prep_patients_temp_queue (person_id int primary key) 
                        (
                         select distinct q.person_id from flat_prep_summary_temp_queue q
							inner join etl.flat_obs t0 using (person_id)
							where t0.encounter_type in (133,134)
                        );
                        
						drop table if exists flat_prep_summary_0a;
						create temporary table flat_prep_summary_0a
						(select
							t1.person_id,
							t1.visit_id,
							t1.encounter_id,
							t1.encounter_datetime,
							t1.encounter_type,
							t1.location_id,
							t1.obs,
							t1.obs_datetimes,
                             case
                                when t1.encounter_type in (1,2,3,4,10,14,15,17,19,26,32,33,34,47,105,106,112,113,114,117,120,127,128,138,140,153,154,158,162,163, 186, 133, 134) then 1
                                else 0
                            end as is_clinical_encounter,
                            
                            case
                                when t1.encounter_type in (133, 134) then 1
                                else 0
                            end as is_prep_clinical_encounter,

                            case
                                when t1.encounter_type in (116) then 20
                                when t1.encounter_type in (1,2,3,4,10,14,15,17,19,26,32,33,34,47,105,106,112,113,114,115,117,120,127,128,138, 140, 153,154,158,162,163,186, 133, 134) then 10
                                when t1.encounter_type in (129) then 5 
                                else 1
                            end as encounter_type_sort_index
							from etl.flat_obs t1
								join prep_patients_temp_queue t0 using (person_id)
						);

						drop table if exists flat_prep_summary_0;
						create temporary table flat_prep_summary_0(index encounter_id (encounter_id), index person_enc (person_id,encounter_datetime))
						(select * from flat_prep_summary_0a
						order by person_id, encounter_datetime, 
                        encounter_type_sort_index
						);


						select @prev_id := -1;
						select @cur_id := -1;
						select @enrollment_date := null;
						select @cur_location := null;
						select @cur_rtc_date := null;
						select @prev_rtc_date := null;

						select @prep_start_date := null;
                        select @prev_prep_meds := null;
                        select @cur_prep_meds := null;

						drop temporary table if exists flat_prep_summary_1;
						create temporary table flat_prep_summary_1 (
							primary key encounter_id (encounter_id),
							index person_date (person_id, encounter_datetime),
							index location_rtc (location_id,rtc_date),
							index person_uuid (uuid),
                            index person_id (person_id),
							index location_enc_date (location_id,encounter_datetime),
							index enc_date_location (encounter_datetime, location_id)
                        )
						(select
                        now() as date_created,
							@prev_id := @cur_id as prev_id,
							@cur_id := t1.person_id as cur_id,
							t1.person_id,
							p.uuid as uuid,
							t1.visit_id,
							t1.encounter_id,
							t1.encounter_datetime,
							t1.encounter_type,
                            is_prep_clinical_encounter,
                            CASE
                                 WHEN
                                     obs REGEXP '!!7015='
                                         AND (@enrollment_date IS NULL
                                         || (@enrollment_date IS NOT NULL
                                         AND @prev_id != @cur_id))
                                 THEN
                                     @enrollment_date:='1900-01-01'
                                 WHEN
										(@enrollment_date IS NULL
                                         || (@enrollment_date IS NOT NULL
                                         AND @prev_id != @cur_id))
                                 THEN
                                     @enrollment_date:=DATE(encounter_datetime)
                                 WHEN @prev_id = @cur_id THEN @enrollment_date
                                 ELSE @enrollment_date:=NULL
                             END AS enrollment_date, 
                             
							case 
								when @prev_id != @cur_id then @prev_discontinued_prep := null
								else  @prev_discontinued_prep := @discontinued_prep
							end as prev_discontinued_prep,
                             
                             CASE
								WHEN  obs REGEXP '!!9772=6102' then @discontinued_prep := 1
								WHEN  obs REGEXP '!!9772=' then @discontinued_prep := null
                                WHEN @prev_id = @cur_id then @discontinued_prep
                                ELSE @discontinued_prep := null
							END as  discontinued_prep,
                            
                            case
								when @discontinued_prep = 1 and  @prev_discontinued_prep is null  then @discontinued_prep_date := date(encounter_datetime)
                                when @discontinued_prep is null and  @prev_discontinued_prep = 1 then @discontinued_prep_date := null
                                when @prev_id = @cur_id then date(@discontinued_prep_date)
                                else @discontinued_prep_date := null
							end as discontinued_prep_date,
                            case
								WHEN  obs REGEXP '!!1040=703' OR (@discontinued_prep = 1 and obs REGEXP '!!1596=1169') then @turned_positive := 1
								WHEN  obs REGEXP '!!1040=' then @turned_positive := null
                                WHEN @prev_id = @cur_id then @turned_positive
                                ELSE @turned_positive := null
							END as  turned_positive,
                            
                            case
								when @turned_positive = 1 and  @prev_discontinued_prep is null  then @turned_positive_date := date(encounter_datetime)
                                when @turned_positive is null and  @prev_discontinued_prep = 1 then @turned_positive_date := null
                                when @prev_id = @cur_id then date(@turned_positive_date)
                                else @turned_positive_date := null
							end as turned_positive_date,
						
                             CASE
								 WHEN
									 (@enrollment_location_id IS NULL
										 || (@enrollment_location_id IS NOT NULL
										 AND @prev_id != @cur_id))
										 AND obs REGEXP '!!7030=5622'
								 THEN
									 @enrollment_location_id:=9999
								 WHEN
									 obs REGEXP '!!7015='
										 AND (@enrollment_location_id IS NULL
										 || (@enrollment_location_id IS NOT NULL
										 AND @prev_id != @cur_id))
								 THEN
									 @enrollmen_location_id:=9999
								 WHEN
									 encounter_type NOT IN (21 , @lab_encounter_type)
										 AND (@enrollment_location_id IS NULL
										 || (@enrollment_location_id IS NOT NULL
										 AND @prev_id != @cur_id))
								 THEN
									 @enrollment_location_id:= location_id
								 WHEN @prev_id = @cur_id THEN @enrollment_location_id
								 ELSE @enrollment_location_id:=NULL
							END AS enrollment_location_id,

							case
								when location_id then @cur_location :=  cast(location_id as SIGNED)
								when @prev_id = @cur_id then cast(@cur_location as SIGNED)
								else null
							end as location_id,

							case
						        when @prev_id=@cur_id then @prev_rtc_date := @cur_rtc_date
						        else @prev_rtc_date := null
							end as prev_rtc_date,

							# 5096 = return visit date
							case
								when obs regexp "!!5096=" then @cur_rtc_date := date(replace(replace((substring_index(substring(obs,locate("!!5096=",obs)),@sep,1)),"!!5096=",""),"!!",""))
								when @prev_id = @cur_id then if(@cur_rtc_date > encounter_datetime, date(@cur_rtc_date),null)
								else @cur_rtc_date := null
							end as rtc_date,
                            
                            case
                                when p.dead or p.death_date then @death_date := p.death_date
                                when obs regexp "!!1570=" then @death_date := replace(replace((substring_index(substring(obs,locate("!!1570=",obs)),@sep,1)),"!!1570=",""),"!!","")
                                when @prev_id != @cur_id or @death_date is null then
                                    case
                                        when obs regexp "!!(1734|1573)=" then @death_date := encounter_datetime
                                        when obs regexp "!!(1733|9082|6206)=159!!" or t1.encounter_type=31 then @death_date := encounter_datetime
                                        else @death_date := null
                                    end
                                else @death_date
                            end as death_date,
                            
                            case 
								when @prev_id = @cur_id then @prev_prep_meds := @cur_prep_meds
								else  @prev_prep_meds := null
							end as prev_prep_meds,
                            
							case
                                when obs regexp "!!9773=1066" then @cur_prep_meds := null
                                when obs regexp "!!9772=6102" then @cur_prep_meds := null
                                when obs regexp "!!9774=" then @cur_prep_meds := etl.normalize_arvs(obs,'9774')
                                when @prev_id = @cur_id then @cur_prep_meds
                                else @cur_prep_meds := null
                            end as cur_prep_meds,
                            
                              case 
								when @first_prep_regimen is null and @cur_prep_meds is not null then @first_prep_regimen := @cur_prep_meds
								when @prev_id = @cur_id and @first_prep_regimen is not null then @first_prep_regimen
                                else @first_prep_regimen := null
							end as first_prep_regimen,
                            
                            --  case
-- 								when obs regexp "!!9789=" and @prep_start_date is null  then 1
-- 								when @prev_id != @cur_id and @cur_prep_meds is not null then 2
--                                 when @prev_id = @cur_id and (@prev_prep_meds <> @cur_prep_meds or @cur_prep_meds is not null)  then 3
--                                 when @prev_id = @cur_id then 4
--                                 else 5
-- 							end as prep_start_date_branch,

                            case
								when obs regexp "!!9789=" and @prep_start_date is null  then @prep_start_date := date(replace(replace((substring_index(substring(obs,locate("!!9789=",obs)),@sep,1)),"!!9789=",""),"!!",""))
								when @prev_id != @cur_id and @cur_prep_meds is not null then @prep_start_date := date(encounter_datetime)
                                when @prev_id = @cur_id and (@prev_prep_meds <> @cur_prep_meds or @cur_prep_meds is not null) then @prep_start_date := date(encounter_datetime)
                                when @prev_id = @cur_id then date(@pep_start_date)
                                else @pep_start_date := null
							end as prep_start_date,
                            
                            case
								when @prev_id != @cur_id and @pep_start_date is not null then @inital_prep_start_date := @pep_start_date
                                when @prev_id = @cur_id and @inital_prep_start_date is null and @pep_start_date is not null then @inital_prep_start_date := @pep_start_date
                                when @prev_id = @cur_id and @inital_prep_start_date is not null then @inital_prep_start_date
                                when @prev_id != @cur_id then @inital_prep_start_date := null
                                else @inital_prep_start_date
							end as inital_prep_start_date,
                            
                            etl.get_arv_names(@cur_prep_meds) as cur_prep_meds_names,  
							etl.get_arv_names(@first_prep_regimen) AS first_prep_regimen_names,
                             p.birthdate, 
                             p.gender
                          

						from flat_prep_summary_0 t1
							join amrs.person p using (person_id)
						);
                        
                        
						-- select * from flat_prep_summary_1 order by person_id, encounter_datetime;
						
                        replace into flat_prep_summary_v1_1
						(select
							*
							from flat_prep_summary_1);


						-- WEEKLY
                        drop temporary table if exists prep_summary_in_queue;
						create temporary table prep_summary_in_queue               
						(index (person_id), index(person_id, encounter_datetime),  index(encounter_id), index(encounter_datetime), index(rtc_date))
						(select * 
						 from 
						  flat_prep_summary_1
							where
							encounter_datetime >= '2018-01-01'
							AND is_prep_clinical_encounter = 1
							order by person_id, encounter_datetime
						);
                        
                        drop temporary table if exists patient_week_encounters;
						create temporary table patient_week_encounters               
						(index (person_id), index(person_id, week, encounter_id))
						( 
						 select * from (select 
							 *
							 from 
							 surge_week w
							 join
							 prep_summary_in_queue h
							 WHERE
							h.encounter_datetime < DATE_ADD(end_date, INTERVAL 1 DAY)
						ORDER BY h.person_id , week, h.encounter_datetime desc , rtc_date
						) p group by person_id, week);
                        
                        
                        drop temporary table if exists prep_weekly_report_dataset_0;
						create temporary table prep_weekly_report_dataset_0               
						( 
                         primary key elastic_id (elastic_id),
                         index (person_id),  
                         index (person_id, week), 
                         index(week), 
                         index(location_id, week), 
                         index(encounter_datetime))
						(SELECT
						   concat(week, person_id) as elastic_id,
							location_id,
							person_id, 
							uuid AS person_uuid,
							DATE(birthdate) AS birthdate,
							death_date,
							CASE
								WHEN
									TIMESTAMPDIFF(YEAR, birthdate, end_date) > 0
								THEN
									@age:=ROUND(TIMESTAMPDIFF(YEAR, birthdate, end_date),
											0)
								ELSE @age:=ROUND(TIMESTAMPDIFF(MONTH,
											birthdate,
											end_date) / 12,
										2)
							END AS age,
							gender,
							encounter_id, 
							encounter_datetime,
                            @encounter_week := yearweek(encounter_datetime) as encounter_week,
							week,
							prev_rtc_date,
                            @prev_rtc_week := yearweek(prev_rtc_date) as prev_rtc_week,
							rtc_date,
							@rtc_week := yearweek(rtc_date) as rtc_week,
                            cur_prep_meds_names,
                            first_prep_regimen,
                            prep_start_date,
                            
                            CASE
								WHEN @encounter_week = week THEN @visit_this_week := 1
								ELSE @visit_this_week := 0 
							END AS visit_this_week,
							
							CASE
								WHEN @prev_rtc_week = week THEN @appointment_this_week := 1
								WHEN @rtc_week = week THEN @appointment_this_week := 1
								ELSE @appointment_this_week := 0 
							END AS appointment_this_week,
							
							IF(@visit_this_week = 1 AND @appointment_this_week = 1, 1, 0)  AS scheduled_visit_this_week,
							
							IF(@visit_this_week = 1  AND @appointment_this_week <> 1 AND @encounter_week < @prev_rtc_week
								,1,0) AS early_appointment_this_week,
								
							IF(@visit_this_week = 1  AND @appointment_this_week <> 1 AND @encounter_week > @prev_rtc_week
								,1,0) AS late_appointment_this_week,
								
							IF(@visit_this_week = 0  AND @appointment_this_week = 1,1,0) AS missed_appointment_this_week,

							 CASE 
							 WHEN @visit_this_week = 1  THEN @weeks_since_rtc :=  week - @rtc_week
							 WHEN @visit_this_week <> 1 AND @rtc_week is not null THEN @weeks_since_rtc :=  week - @rtc_week 
                             WHEN @visit_this_week <> 1 AND @prev_rtc_week is not null THEN @weeks_since_rtc :=  week - @prev_rtc_week 
							 ELSE @weeks_since_rtc := null
							 END AS weeks_since_rtc,
							 
							 CASE
								WHEN 
									DATE(start_date) > DATE(death_date) 
								THEN @status:='dead'
								WHEN 
								 	week >= yearweek(discontinued_prep_date) 
									THEN 
								    @status:='discontinued'
								WHEN
									@weeks_since_rtc < 1
								THEN
									@status:='active'
								WHEN
									@weeks_since_rtc >= 1 and @weeks_since_rtc <= 4
								THEN
									@status:='defaulter'
								WHEN
									@weeks_since_rtc > 4
								THEN
									@status:='ltfu'
								ELSE @status:='unknown'
							END AS status,
                            
                            if( @status = 'active', 1, 0) as active_on_prep_this_week,
                            if( @status = 'defaulter', 1, 0) as prep_defaulter_this_week,
							if( @status = 'ltfu', 1, 0) as prep_ltfu_this_week,
                            if( @status = 'discontinued', 1, 0) as prep_discontinued_this_week,
                            
							if(yearweek(enrollment_date) = week, 1, 0) as enrolled_in_prep_this_week,
							if(yearweek(discontinued_prep_date) = week, 1, 0) as discontinued_from_prep_this_week,
                            case when yearweek(turned_positive_date) = week then @turned_positive_this_week = 1
                            else @turned_positive_this_week = 0  end as turned_positive_this_week,
                            if((@turned_positive_this_week = 1 and @status = 'discontinued'), 1, 0) as prev_on_prep_and_turned_positive
                            
                            from 
                            patient_week_encounters
						 );
                         
                         replace into prep_weekly_report_dataset_v1_1
						(select
							*
							from prep_weekly_report_dataset_0);
                        


						SET @dyn_sql=CONCAT('delete t1 from ',@queue_table,' t1 join flat_prep_summary_temp_queue t2 using (person_id);'); 

													PREPARE s1 from @dyn_sql; 
													EXECUTE s1; 
													DEALLOCATE PREPARE s1;  
											
											
											
											SET @dyn_sql=CONCAT('select count(*) into @person_ids_count from ',@queue_table,';'); 
											PREPARE s1 from @dyn_sql; 
											EXECUTE s1; 
											DEALLOCATE PREPARE s1;  
											
											

											set @cycle_length = timestampdiff(second,@loop_start_time,now());
											
											set @total_time = @total_time + @cycle_length;
											set @cycle_number = @cycle_number + 1;
											
											
											set @remaining_time = ceil((@total_time / @cycle_number) * ceil(@person_ids_count / cycle_size) / 60);
											

						SELECT 
							@person_ids_count AS 'persons remaining',
							@cycle_length AS 'Cycle time (s)',
							CEIL(@person_ids_count / cycle_size) AS remaining_cycles,
							@remaining_time AS 'Est time remaining (min)';

				 end while;

				 select @end := now();
				 insert into etl.flat_log values (@start,@last_date_created,@table_version,timestampdiff(second,@start,@end));
				 select concat(@table_version," : Time to complete: ",timestampdiff(minute, @start, @end)," minutes");

		END