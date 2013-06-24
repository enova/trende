class CreatingStagingTable < ActiveRecord::Migration
  def change
    create_table :staging_table do |t|
      t.string :data_type
      t.timestamp :time_stamp
      t.integer :magnitude
      t.string :city
      t.string :state
      t.string :postal_code
      t.string :primary_attribute
      t.string :secondary_attribute
    end
  end
end
