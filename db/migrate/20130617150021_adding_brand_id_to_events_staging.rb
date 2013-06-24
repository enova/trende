class AddingBrandIdToEventsStaging < ActiveRecord::Migration
  def change
  	change_table :staging_table do |t|
			t.integer :brand_id
  	end	
  	change_table :events do |t|
  		t.integer :brand_id
  	end
  end
end
