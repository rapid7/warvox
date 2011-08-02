class CreateProviders < ActiveRecord::Migration
  def self.up
    create_table :providers do |t|
      t.text :name
      t.text :host
      t.integer :port
      t.text :user
      t.text :pass
      t.integer :lines

      t.timestamps
    end
  end

  def self.down
    drop_table :providers
  end
end
