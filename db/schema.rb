# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130603130020) do

  create_table "data_points", :force => true do |t|
    t.string   "data_type"
    t.datetime "time_stamp"
    t.integer  "magnitude"
    t.string   "point",               :limit => nil
    t.string   "primary_attribute"
    t.string   "secondary_attribute"
  end

  create_table "data_points_by_state_and_hour", :force => true do |t|
    t.string  "data_type"
    t.string  "state"
    t.decimal "loc_x"
    t.decimal "loc_y"
  end

  create_table "data_points_by_zip_and_hour", :force => true do |t|
    t.string  "data_type"
    t.integer "zip"
    t.decimal "loc_x"
    t.decimal "loc_y"
  end

  create_table "loans", :force => true do |t|
    t.string   "loan_type"
    t.decimal  "loan_amount"
    t.text     "street_address"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "referred_from"
    t.datetime "date_time"
  end

  create_table "raw_input_data_points", :force => true do |t|
    t.string   "data_type"
    t.datetime "time_stamp"
    t.integer  "magnitude"
    t.string   "city"
    t.string   "state"
    t.integer  "zip"
    t.decimal  "loc_x"
    t.decimal  "loc_y"
    t.string   "primary_attribute"
    t.string   "secondary_attribute"
  end

end
