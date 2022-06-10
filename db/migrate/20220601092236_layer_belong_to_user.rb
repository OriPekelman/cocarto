class LayerBelongToUser < ActiveRecord::Migration[7.0]
  def up
    execute "TRUNCATE layers CASCADE"
    add_reference :layers, :user, foreign_key: true, type: :uuid, null: false # rubocop:disable Rails/NotNullColumn
  end

  def down
    remove_reference :layers, :user
  end
end
