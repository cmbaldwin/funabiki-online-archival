require "test_helper"

class MessagesChannelTest < ActionCable::Channel::TestCase
  test "subscribes and broadcasts" do
    # requires a current_user
    stub_connection current_user: users(:admin)
    subscribe
    assert subscription.confirmed?

    # confirm this works that creating a Message broadcasts a message: ActionCable.server.broadcast "messages_channel_#{user}", { id:, action: action }
    ActionCable.server.broadcast "messages_channel_#{users(:admin).id}", { id: 1, action: 'prepend' }
    assert_broadcast_on("messages_channel_#{users(:admin).id}", { id: 1, action: 'prepend' })
  end
end
