class CreateCampaigns < ActiveRecord::Migration[7.2]
  def change
    create_table :campaigns do |t|
      t.string :title, null: false
      t.string :status, default: "pending", null: false

      t.timestamps
    end
  end
end
