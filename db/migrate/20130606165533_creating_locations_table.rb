class CreatingLocationsTable < ActiveRecord::Migration
  def change
    create_table :locations do |t|
      t.string :postal_code
      t.string :state
      t.string :city
      t.decimal :lat
      t.decimal :long
    end
  end
end
