class AddingDataSourceToStagingAndEvents < ActiveRecord::Migration
  def change
    change_table :staging_table do |t|
      t.string :data_source
    end
    change_table :events do |t|
      t.string :data_source
    end
  end
end
