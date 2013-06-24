class CreatingBrandsTable < ActiveRecord::Migration
  def change
  	create_table :brands do |t|
  		t.integer :id
  		t.string :brand_code
  		t.string :country_cd
  	end
  end
end
