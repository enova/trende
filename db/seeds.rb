# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

us_locations_file = "#{Rails.root.to_s}/data/seed/us_locations.csv"
uk_locations_file = "#{Rails.root.to_s}/data/seed/postal_centers.csv"
brands_file = "#{Rails.root.to_s}/data/seed/brands.csv"

Location.connection.execute("copy locations (city, state, postal_code, lat, long) from '#{us_locations_file}' with delimiter ',';\n")
Location.connection.execute("copy locations (city, state, postal_code, lat, long) from '#{uk_locations_file}' with delimiter ',';\n")
Brand.connection.execute("copy brands (id,brand_code,country_cd) from '#{brands_file}' with delimiter ',';\n")
