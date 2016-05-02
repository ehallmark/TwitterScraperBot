require 'net/http' 
require 'uri' 
require 'timeout'
require 'watir'
require 'watir-webdriver'
require 'watir-dom-wait'

class RawTweet < ActiveRecord::Base      
  validates_uniqueness_of :status_id
  validates_presence_of [:status_id, :status_date, :screen_name, :status_text]
  validates :user_mentioned, length: { minimum: 0, allow_nil: false, message: "can't be nil" }
  validates :user_hashtagged, length: { minimum: 0, allow_nil: false, message: "can't be nil" }
  
  scope :on_date_of, lambda{|date| where("status_date = ?",date)}
  scope :mentioning, lambda{|screen_name| where("lower(user_mentioned) ilike '%#{screen_name.downcase}%' ") }
  scope :tweeted_by, lambda{|screen_name| where("lower(screen_name) ilike '#{screen_name.downcase}' ") }
  scope :with_hashtags, lambda{|terms| 
    where(terms.each.collect{|name| " lower(user_hashtagged) ilike '%#{name.downcase}%' " }.join(" OR ")) 
  }
  scope :with_terms, lambda{|terms| 
    where(terms.each.collect{|name| " lower(status_text) ilike '%#{name.downcase}%' " }.join(" OR ")) 
  }
    
  def self.first_date
    Date.new(2010,1,1)
  end
  def self.last_date
    Date.today
  end    
  
  def self.download_database(params)
    startDate, endDate, hashtags, terms, screen_names, mentions = extractTwitterParams(params)
    seedHelper true, startDate, endDate, hashtags, terms, screen_names, mentions
  end  
  
  def self.download_csv params
    startDate, endDate, hashtags, terms, screen_names, mentions = extractTwitterParams(params)
    
    spreadsheet_name = "master"
  
    book = Spreadsheet::Workbook.new 
    sheet1 = book.create_worksheet :name => spreadsheet_name
    
    methods = [:status_id, :status_date, :screen_name, :status_text, :user_mentioned, :user_hashtagged]

    sheet1.row(0).replace methods
    results = seedHelper false, startDate, endDate, hashtags, terms, screen_names, mentions
     
    if results.present?
      results.each_with_index do |result,i|
        sheet1.row(i+1).replace(methods.collect{|m| result.send(m) })
      end
    end
    
    buffer = StringIO.new ''
    book.write(buffer)
    buffer.rewind
      
    return buffer.string.bytes.to_a.pack("C*")
  end 
  
  
  def self.seedHelper database=false, startDate=nil, endDate=nil, hashtags=nil, terms=nil, screen_names=nil, mentions=nil
    return unless hashtags.present? or terms.present? or screen_names.present? or mentions.present?
    
    #set up bot
    browser = Watir::Browser.new :chrome
    browser.goto "twitter.com"

    # start setting URL with search parameters
    base_string = "https://twitter.com/search?f=tweets&vertical=default&q="
    p = []
    
    if hashtags.present?
      hashtags.each do |hashtag| p.push "%23#{hashtag}" if hashtag.present? end
    end
    if terms.present?
      terms.each do |term| p.push "#{term}" if term.present? end
    end
    if mentions.present?
      mentions.each do |mention| p.push "to%3A#{mention}" if mention.present? end
    end
    if screen_names.present?
      screen_names.each do |screen_name| p.push "from%3A#{screen_name}" if screen_name.present? end
    end
    
    if startDate.present?
      start_date_string = startDate.strftime("%Y-%m-%d")
      p.push("since%3A#{start_date_string}")
    end
    
    if endDate.present?
      end_date_string = (endDate + 1.day).strftime("%Y-%m-%d")
      p.push("until%3A#{end_date_string}")
    end
    
    # create full url      
    search_url = [base_string,p.join("%20"),"&src=sprv"].join
    
    browser.goto search_url
    sleep(3)
    
    doc = Nokogiri::HTML.parse(browser.html) # Save a call by using the already downloaded response.  
    stream = doc.css("div.AppContainer div.AppContent-main div.content-main div.stream-container div.stream li div.tweet")
      
      # scroll to bottom
    height_before = 0
    height_after = stream.to_a.length
    smallest = 0
    if height_before < height_after
      initial = 0
      final = browser.html.length
      while final > initial
        initial = final
        browser.scroll.to :bottom  
        sleep(4)
        final = browser.html.length
      end
      # ingest all results
      ingestAll(browser,database)
    end
  end
  
  def self.ingestAll browser, database
    doc = Nokogiri::HTML.parse(browser.html) 
    stream = doc.css("div.AppContainer div.AppContent-main div.content-main div.stream-container div.stream li div.tweet")
    stream.send(database ? :each : :collect) do |tweet|                     
      status_id = (tweet['data-tweet-id'] || '').strip     
      next unless status_id.present? 
      
      attrs = {}
       
      attrs[:status_id] = status_id
          
      # tweet related attrs
      begin attrs[:status_date] = Time.at(tweet.css('a.tweet-timestamp span._timestamp').first['data-time'].to_i) rescue nil end
      attrs[:status_text] = tweet.css('div.js-tweet-text-container').text.strip.gsub("-"," ").gsub(/[^A-Za-z0-9 ]/, '')
        
      attrs[:screen_name] = (tweet['data-screen-name'] || '').strip
        
      # user mentions
      attrs[:user_mentioned] = tweet['data-mentions'] || ""
        
      # hashtags
      attrs[:user_hashtagged] = tweet.css('div.js-tweet-text-container p a.twitter-hashtag').to_a.collect{|h| h.text.downcase.strip.gsub(/[^A-Za-z]/, '') }.join(" ")
                     
      # create record
      if database
        RawTweet.create(attrs)
      else
        RawTweet.new(attrs)
      end
    end
  end
  
end
