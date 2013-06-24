class AddingRemoteIdToEventsAndStaging < ActiveRecord::Migration
  def change
    change_table :staging_table do |t|
      t.integer :remote_id
    end
    change_table :events do |t|
      t.integer :remote_id
    end
  end
end
