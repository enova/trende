namespace :trende do
  desc "Clear staging table"
  task :clear_staging => :environment do
    puts "--------------------**** Clearing Staging Table ****--------------------"
    ActiveRecord::Base.connection.execute("delete from staging_table")
    puts "--------------------**** Staging Table Cleared ****--------------------"
  end

  desc "Clear locations table"
  task :clear_locations => :environment do
    puts "--------------------**** Clearing Locations Table ****--------------------"
    ActiveRecord::Base.connection.execute("delete from locations")
    puts "--------------------**** Locations Table Cleared ****--------------------"
  end

  desc "Clear events table"
  task :clear_events => :environment do
    puts "--------------------**** Clearing Events Table ****--------------------"
    ActiveRecord::Base.connection.execute("delete from events")
    puts "--------------------**** Events Table Cleared ****--------------------"
  end

  desc "Loads new data from given csv"
  task :load_new_data, [:csv_filename, :should_partition] => [:environment] do |t, args|
    begin
      if args.csv_filename.nil?
        puts "ERROR: Expecting [data_file] as input arguments"
      else
        if args.should_partition
          args.should_partition == 'true' ? args.should_partition = true : args.should_partition = false
        else
          args.with_defaults :should_partition => true
        end
        Rake::Task['heatmap:clear_staging'].reenable
        Rake::Task['heatmap:clear_staging'].invoke
        puts "--------------------**** Loading new data ****--------------------"

        data_file = args.csv_filename
        sh "sh sanitize_input.sh #{Rails.root}/data/#{data_file} #{data_file}_parsed.txt"

        puts "--------------------**** Copying to staging ****--------------------"
        ActiveRecord::Base.connection.execute("copy staging_table (remote_id,brand_id,data_type,time_stamp,magnitude,primary_attribute,secondary_attribute,city,state,postal_code) from '#{Rails.root}/#{data_file}_parsed.txt' with csv delimiter ',' quote '\"'")
        ActiveRecord::Base.connection.execute("update staging_table set data_source = '#{data_file}'")
        ActiveRecord::Base.connection.execute("update staging_table set postal_code = upper(postal_code)")
        ActiveRecord::Base.connection.execute("update staging_table set secondary_attribute = 'other' where secondary_attribute is null")
        puts "--------------------**** Copying to staging: Complete ****--------------------"
        if args.should_partition
          puts "--------------------**** Auto-partitioning / Checking partitions up-to-date Events ****--------------------"
          autopartition_events
          puts "--------------------**** Partitioning Complete ****--------------------"
        end
        puts "--------------------**** Copying to events ****--------------------"
        ActiveRecord::Base.connection.execute("insert into events (remote_id, brand_id, data_source, data_type, time_stamp, magnitude, primary_attribute, secondary_attribute, location_id) select stt.remote_id, stt.brand_id, stt.data_source, stt.data_type, stt.time_stamp, stt.magnitude, stt.primary_attribute, stt.secondary_attribute, loc.id from staging_table stt join locations loc using (postal_code)")
        puts "--------------------**** Copying to events: Complete ****--------------------"

        sh "rm #{data_file}_parsed.txt"
        puts "--------------------**** Load Complete ****--------------------"
      end
    rescue RuntimeError => e
      begin
        sh "rm #{data_file}_parsed.txt"
      rescue RuntimeError => e
        puts "heatmap:load_new_data task failed with error: #{e}"
      end
    end
  end

  desc "Create indices on tables"
  task :create_indices => :environment do
    puts "---------------------**** Creating Indices ****-------------------"
    ActiveRecord::Base.connection.execute("create index postal_idx_loc on locations using btree(postal_code)")
    puts "---------------------**** Indices created ****-------------------"
  end

  desc "Drop indices"
  task :drop_indices => :environment do
    puts "---------------------**** Dropping Indices ****-------------------"
    ActiveRecord::Base.connection.execute("drop index postal_idx_loc")
    puts "---------------------**** Indices dropped ****-------------------"
  end

  desc "Soft clear of just staging and events tables"
  task :clear => [:clear_staging, :clear_events] do
    puts "-------------**** Cleared staging and events ****--------------"
  end

end

namespace :db do
  desc "Warning: This drops your database, not just clears rows"
  task :hard_reset => [:drop, :create, :migrate, :seed] do
    Rake::Task['heatmap:create_indices'].invoke
  end
end

#Partitioning Logic:

#                                                               Events
#                                                                 |
#                  -----------------------------------------------------------------------------------------------
#                 |                               |                               |                               |
#              Brand1                          Brand2                          Brand3                          Brand4
#                 |                               |                               |                               |
#        -------------------             -------------------             -------------------             -------------------
#       |      |            |           |      |            |           |      |            |           |      |            |
#   y2012m01 y2012m02 ... y2013m06  y2012m01 y2012m02 ... y2013m06  y2012m01 y2012m02 ... y2013m06   y2012m01 y2012m02 ... y2013m06
#


def extract_partition_elements(partitionable)
  partition_elements = partitionable["partitionables"].delete("()").split(",")
  two_digit_month = partition_elements[0].length == 2 ? partition_elements[0] : "0#{partition_elements[0]}"
  year = partition_elements[1]
  brand = partition_elements[2]
  adjusted_year = year
  adjusted_month = two_digit_month
  if two_digit_month.to_i == 12
    adjusted_month = 0
    adjusted_year = adjusted_year.to_i + 1
  end
  return adjusted_month, adjusted_year, brand, two_digit_month, year
end

def create_brand_month_partition(adjusted_month, adjusted_year, brand, pg_connection, two_digit_month, year)
  pg_connection.execute("create table events_brand_#{brand}_y#{year}m#{two_digit_month} (check (time_stamp >= DATE '#{year}-#{two_digit_month}-01' and time_stamp < DATE '#{adjusted_year}-#{adjusted_month.to_i+1}-01')) inherits (events_brand_#{brand})")
  pg_connection.execute("create index events_brand_#{brand}_y#{year}m#{two_digit_month}_mag_idx on events_brand_#{brand}_y#{year}m#{two_digit_month} (magnitude)")
  pg_connection.execute("create index events_brand_#{brand}_y#{year}m#{two_digit_month}_sec_attr_idx on events_brand_#{brand}_y#{year}m#{two_digit_month} (secondary_attribute)")
  pg_connection.execute("create index events_brand_#{brand}_y#{year}m#{two_digit_month}_loc_idx on events_brand_#{brand}_y#{year}m#{two_digit_month} (location_id)")
end

def create_brand_partition(brand, pg_connection)
  pg_connection.execute("create table events_brand_#{brand} (check (brand_id = #{brand})) inherits (events)")
end

def add_new_conditional_to_trigger_function(adjusted_month, adjusted_year, brand, pg_connection, two_digit_month, year)
  trigger_function = pg_connection.execute("select pg_get_functiondef(oid) as def from pg_proc where proname = 'event_insert_trigger'").first["def"]
  insert_new_conditional_at = trigger_function.upcase.index(/ELSE/) - 1
  trigger_function.insert(insert_new_conditional_at, <<-eos
                                                  ELSIF ( NEW.time_stamp >= DATE '#{year}-#{two_digit_month}-01' AND NEW.time_stamp < DATE '#{adjusted_year}-#{adjusted_month.to_i+1}-01' AND NEW.brand_id = #{brand} ) THEN
                                                  INSERT INTO events_brand_#{brand}_y#{year}m#{two_digit_month} VALUES (NEW.*);
  eos
  )
  trigger_function
end

def create_trigger(pg_connection)
  pg_connection.execute("CREATE TRIGGER insert_event_trigger BEFORE INSERT ON events FOR EACH ROW EXECUTE PROCEDURE event_insert_trigger()")
end

def autopartition_events
  pg_connection = ActiveRecord::Base.connection
  partitionables = pg_connection.execute("select distinct(date_part('month',time_stamp), date_part('year',time_stamp), brand_id) as partitionables from staging_table")
  trigger_function = ""
  partitionables.each do |partitionable|
    adjusted_month, adjusted_year, brand, two_digit_month, year = extract_partition_elements(partitionable)
    brand_month_partition_exists = pg_connection.execute("select exists (select * from pg_tables where schemaname = 'public' and tablename='events_brand_#{brand}_y#{year}m#{two_digit_month}')").first["exists"]
    if brand_month_partition_exists == 'f'
      brand_partition_exists = pg_connection.execute("select exists (select * from pg_tables where schemaname = 'public' and tablename='events_brand_#{brand}')").first["exists"]
      if brand_partition_exists == 't'
        create_brand_month_partition(adjusted_month, adjusted_year, brand, pg_connection, two_digit_month, year)
      else
        create_brand_partition(brand, pg_connection)
        create_brand_month_partition(adjusted_month, adjusted_year, brand, pg_connection, two_digit_month, year)
      end
      trigger_function_exists = pg_connection.execute("select exists(select pg_get_functiondef(oid) from pg_proc where proname = 'event_insert_trigger')").first["exists"]
      if trigger_function_exists == 't'
        trigger_function = add_new_conditional_to_trigger_function(adjusted_month, adjusted_year, brand, pg_connection, two_digit_month, year)
      else
        #Create new trigger
        trigger_function = <<-eos
                CREATE OR REPLACE FUNCTION event_insert_trigger()
                RETURNS TRIGGER AS $insert_event_trigger$
                BEGIN
                  IF ( NEW.time_stamp >= DATE '#{year}-#{two_digit_month}-01' AND NEW.time_stamp < DATE '#{adjusted_year}-#{adjusted_month.to_i+1}-01' AND NEW.brand_id = #{brand} ) THEN
                  INSERT INTO events_brand_#{brand}_y#{year}m#{two_digit_month} VALUES (NEW.*);
                  ELSE
                  RAISE EXCEPTION 'No matching brand-year-month partition.  Fix the event_insert_trigger() function!';
                  END IF;
                  RETURN NULL;
                END;
                $insert_event_trigger$
                LANGUAGE plpgsql;
        eos
      end
      pg_connection.execute(trigger_function)
    end
  end
  trigger_exists = pg_connection.execute("select exists (select tgname from pg_trigger where tgname='insert_event_trigger');").first["exists"]
  if trigger_exists == 'f'
    create_trigger(pg_connection)
  end
  pg_connection.execute("set constraint_exclusion = on")
end
