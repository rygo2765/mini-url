class RemoveClickedAtFromVisits < ActiveRecord::Migration[7.2]
  def change
    remove_column :visits, :clicked_at, :datetime
  end
end
