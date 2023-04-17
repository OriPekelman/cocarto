class NoDefaultEmail < ActiveRecord::Migration[7.0]
  def change
    change_column_default :users, :email, from: "", to: nil
  end
end
