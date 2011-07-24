# -*- coding: utf-8 -*-
class ChatController < ApplicationController
  include ChatHelper
  include RoomHelper
  can_edit_on_the_spot

  PageSize = 20

  def index
    @rooms = Room.all_live
  end

  def prev
    @message = Message.find(params[:id])
    @messages = if @message then
                  @message.prev( params[:offset] || 20 )
                else
                  []
                end

    render :action => :messages, :layout => false
  end

  def next
    @message = Message.find(params[:id])
    @messages = @message.next(params[:offset] || 20)

    render :action => :messages, :layout => false
  end

  def show
    @id      = params[:id]
    @message = Message.find(@id)

    @prev_size = int(params[:prev], 5)
    @next_size = int(params[:next], 5)

    @prev_options = [0,1,5,10,15,20,@prev_size].sort.uniq
    @next_options = [0,1,5,10,15,20,@next_size].sort.uniq

    @room = @message.room
    @prev = @message.prev(@prev_size)
    @next = @message.next(@next_size)
  end

  def room
    logger.info "room "
    find_room(params[:id],:not_auth=>true) do
      logger.info @room.title
      @messages = Message.where(:created_at.gte => Time.now.beginning_of_day, :room => @room).order_by(:created_at.desc).limit(PageSize)
      @title = @room.title
    end
  end

  def message
    unless logged?
      flash[:error] = t(:error_message_user_not_login_yet)
      redirect_to :controller => 'chat'
      return
    end
    if request.post? then
      find_room(params[:room_id]) do
        if request[:fileupload]
          create_attach(params[:room_id], params)
        else
          create_message(params[:room_id], params[:message] )
        end
        @room.update_attributes!(:updated_at => Time.now)
      end
    end
    redirect_to :controller => 'chat'
  end

  def update_message_on_the_spot
    message = Message.find(params[:id])
    if request.post? and  logged? and current_user.id == message.user.id
      update_message( message.id,  params[:value])
    end
    render :text => message.body
  end

  private
  def int(s, default)
    if s == nil || s.empty? then
      default
    else
      s.to_i
    end
  end
end
