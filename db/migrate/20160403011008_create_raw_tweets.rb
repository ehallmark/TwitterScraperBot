class CreateRawTweets < ActiveRecord::Migration
  def change
    create_table :raw_tweets do |t|
      t.date :status_date, null: false
      t.string :status_id, null: false, uniq: true
      t.text :status_text, null: false
      t.string :screen_name, null: false
      t.string :user_mentioned, null: false
      t.string :user_hashtagged, null: false
    end
  end
end
