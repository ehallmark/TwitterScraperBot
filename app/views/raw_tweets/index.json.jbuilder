json.array!(@raw_tweets) do |raw_tweet|
  json.extract! raw_tweet, :id, :status_date, :status_id, :status_text, :screen_name
  json.url raw_tweet_url(raw_tweet, format: :json)
end
