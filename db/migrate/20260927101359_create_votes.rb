class CreateVotes < ActiveRecord::Migration[8.1]
  def change
    create_table :votes do |t|
      t.references :event, null: false, foreign_key: true
      t.string :clerk_user_id, null: false
      t.string :choice, null: false

      t.timestamps
    end
    add_index :votes, [ :event_id, :clerk_user_id ], unique: true
  end
end
