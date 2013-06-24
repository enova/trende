class CreatingEventsTable < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.string :data_type
      t.timestamp :time_stamp
      t.integer :magnitude
      t.string :primary_attribute
      t.string :secondary_attribute
      t.integer :location_id
    end
  end
end
