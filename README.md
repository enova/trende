trende
=====
trende takes information about events happening and displays them
in human-readable maps and graphs.

Running trende
-----

###Dependencies
Trende runs on Ruby 1.9.3-p392 and Rails 3.2.13. Results may vary when using
different versions. Our backend utilizes a Postgres 9.2 database. Before 
running trende, ensure that you can access psql from the command line.

###Initial Setup
First, create a database.yml file based on the example file and fill it in with the
appropriate credentials.

    cp config/database.example.yml config/database.yml
    vim config/database.yml
    
Do a quick bundle install:

    bundle install

"Reset" the database, creating tables and seeding with location data:

    rake db:hard_reset
    
To get some locations on the map, use the randomly generated data in trende_data.csv
    
    rake heatmap:load_new_data[trende_data.csv]

Start up the server, and you're ready to go!

    rails s

Note: thin runs on port 3000 by default, so modify that at runtime if necessary:

    rails s -p PORT

###Loading data
Data is loading using a formatted CSV. The format is as follows:

    remote_id, brand_id, data_type, time_stamp, magnitude, primary_attribute, secondary_attribute, city, state, postal_code

Place that file in the data folder. Then, run the rake task used to populate
the database:

    rake heatmap:load_new_data[DATA_FILE_NAME.csv,true/false]

The true/false option is used to specify whether the events table should be 2 level partitioned on brand and year/month for performance improvements. This is set to true by default.
    
###Additional Notes
Trende runs best in Chrome.
