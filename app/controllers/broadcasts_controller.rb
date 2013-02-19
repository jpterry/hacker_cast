require 'securerandom'

class BroadcastsController < ApplicationController
  def new
    if request.post?
      random_channel_id = SecureRandom.urlsafe_base64
      redirect_to  :action => "tx", :key => random_channel_id
    end
  end

  def rx
    @room_id = params[:key]
    @client_id = SecureRandom.urlsafe_base64
    render :template => 'broadcasts/cast'
  end

  def tx
    @room_id = params[:key]
    @client_id = SecureRandom.urlsafe_base64
    @is_broadcaster = true
    render :template => 'broadcasts/cast'
  end
end
