class MessagesChannel < ApplicationCable::Channel
  def subscribed
    stream_from "messages_channel_#{current_user.id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
