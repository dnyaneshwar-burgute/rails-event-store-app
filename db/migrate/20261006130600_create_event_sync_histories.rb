class CreateEventSyncHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :event_sync_histories do |t|
      t.string :status, null: false, default: "draft"

      t.timestamps
    end

    add_index :event_sync_histories, :status
    add_index :event_sync_histories, :created_at
  end
end
