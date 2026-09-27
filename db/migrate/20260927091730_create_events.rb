class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :billetto_id, null: false
      t.string :title, null: false
      t.string :description
      t.datetime :starts_at, null: false
      t.datetime :ends_at
      t.string :image_url
      t.string :url
      t.string :location_name
      t.string :city
      t.integer :upvotes_count, null: false, default: 0
      t.integer :downvotes_count, null: false, default: 0

      t.timestamps
    end
    add_index :events, :billetto_id, unique: true
  end
end
