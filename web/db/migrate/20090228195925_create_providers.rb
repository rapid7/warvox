class CreateProviders < ActiveRecord::Migration
  def self.up
    create_table :providers do |t|
      t.string :name
      t.string :host
      t.integer :port
      t.string :user
      t.string :pass
      t.integer :lines

      t.timestamps
    end
  end

  def self.down
    drop_table :providers
  end
end
