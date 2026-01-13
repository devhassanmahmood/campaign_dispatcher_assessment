class CreateRecipients < ActiveRecord::Migration[7.2]
  def change
    create_table :recipients do |t|
      t.references :campaign, null: false, foreign_key: true
      t.string :name, null: false
      t.string :email
      t.string :phone
      t.string :status, default: "queued", null: false

      t.timestamps
    end

    add_index :recipients, :status
  end
end
