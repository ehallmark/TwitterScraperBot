class RawTweetsController < ApplicationController
  before_action :set_raw_tweet, only: [:show, :edit, :update, :destroy]

  # GET /raw_tweets
  # GET /raw_tweets.json
  def index
    @raw_tweets = RawTweet.order(:status_date)
  end

  # GET /raw_tweets/1
  # GET /raw_tweets/1.json
  def show
  end
  
  def download_csv
    send_data RawTweet.download_csv(params), :type => "application/vnd.ms-excel", :disposition => 'attachment; filename=download.xls'
  end
  
  def download_database
    RawTweet.download_database(params)
    redirect_to :back, notice: "Finished"
  end

  # GET /raw_tweets/new
  def new
    @raw_tweet = RawTweet.new
  end

  # GET /raw_tweets/1/edit
  def edit
  end

  # POST /raw_tweets
  # POST /raw_tweets.json
  def create
    @raw_tweet = RawTweet.new(raw_tweet_params)

    respond_to do |format|
      if @raw_tweet.save
        format.html { redirect_to @raw_tweet, notice: 'Raw tweet was successfully created.' }
        format.json { render :show, status: :created, location: @raw_tweet }
      else
        format.html { render :new }
        format.json { render json: @raw_tweet.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /raw_tweets/1
  # PATCH/PUT /raw_tweets/1.json
  def update
    respond_to do |format|
      if @raw_tweet.update(raw_tweet_params)
        format.html { redirect_to @raw_tweet, notice: 'Raw tweet was successfully updated.' }
        format.json { render :show, status: :ok, location: @raw_tweet }
      else
        format.html { render :edit }
        format.json { render json: @raw_tweet.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /raw_tweets/1
  # DELETE /raw_tweets/1.json
  def destroy
    @raw_tweet.destroy
    respond_to do |format|
      format.html { redirect_to raw_tweets_url, notice: 'Raw tweet was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_raw_tweet
      @raw_tweet = RawTweet.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def raw_tweet_params
      params.require(:raw_tweet).permit(:status_date, :status_id, :status_text, :screen_name)
    end
end
