class CreateGoRoutes < ActiveRecord::Migration
  def change
    create_table :go_links do |t|
    	t.string :key
      	t.string :url
    end
  end
end
