namespace :heatmap do
  desc "Clear staging table"
  task :clear_staging => :environment do
    puts "--------------------**** Clearing Staging Table ****--------------------"
    ActiveRecord::Base.connection.execute("delete from staging_table")
  end

  desc "Clear locations table"
  task :clear_locations => :environment do
    puts "--------------------**** Clearing Locations Table ****--------------------"
    ActiveRecord::Base.connection.execute("delete from locations")
  end

  desc "Clear events table"
  task :clear_events => :environment do
    puts "--------------------**** Clearing Events Table ****--------------------"
    ActiveRecord::Base.connection.execute("delete from events")
  end

  desc "Loads new data from given csv"
  task :load_new_data, [:csv_filename] => [:environment] do |t, args|
    Rake::Task['heatmap:clear_staging'].reenable
    Rake::Task['heatmap:clear_staging'].invoke
    puts "--------------------**** Loading new data ****--------------------"

    if args.csv_filename.nil?
        puts "ERROR: Expecting [data_file] as input arguments"
    else
      data_file = args.csv_filename

      puts "--------------------**** Copying to staging ****--------------------"
      ActiveRecord::Base.connection.execute("copy staging_table (remote_id,brand_id,data_type,time_stamp,magnitude,primary_attribute,secondary_attribute,city,state,postal_code) from '#{Rails.root}/data/#{data_file}' with csv delimiter ',' quote '\"'")
      ActiveRecord::Base.connection.execute("update staging_table set data_source = '#{data_file}'")
      ActiveRecord::Base.connection.execute("update staging_table set postal_code = upper(postal_code)")
      ActiveRecord::Base.connection.execute("update staging_table set secondary_attribute = 'other' where secondary_attribute is null")
      puts "--------------------**** Copying to events ****--------------------"
      ActiveRecord::Base.connection.execute("insert into events (remote_id, brand_id, data_source, data_type, time_stamp, magnitude, primary_attribute, secondary_attribute, location_id) select stt.remote_id, stt.brand_id, stt.data_source, stt.data_type, stt.time_stamp, stt.magnitude, stt.primary_attribute, stt.secondary_attribute, loc.id from staging_table stt join locations loc using (postal_code)")

    end
  end

  desc "Create indices on tables"
  task :create_indices => :environment do
    puts "---------------------**** Creating Indices ****-------------------"
    ActiveRecord::Base.connection.execute("create index postal_idx_loc on locations using btree(postal_code)")
    ActiveRecord::Base.connection.execute("create index postal_idx_evn on events using btree(location_id)")
  end

  desc "Drop indices"
  task :drop_indices => :environment do
    puts "---------------------**** Dropping Indices ****-------------------"
    ActiveRecord::Base.connection.execute("drop index postal_idx_loc")
    ActiveRecord::Base.connection.execute("drop index postal_idx_stg")
    ActiveRecord::Base.connection.execute("drop index postal_idx_evn")
  end

  desc "Soft clear of just staging and events tables"
  task :clear => [:clear_staging, :clear_events] do
    puts "-------------**** Cleared staging and events ****--------------"
  end

end

namespace :db do
  desc "Warning: This drops your database, not just clears rows"
  task :hard_reset => [:drop, :create, :migrate, :seed]do
    Rake::Task['heatmap:create_indices'].invoke
  end
end