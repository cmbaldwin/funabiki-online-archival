# rubocop:disable Style/ClassVars

class SuppliesChannel < ApplicationCable::Channel
  after_subscribe :update_users
  after_unsubscribe :update_users

  @@state_data = {}

  def subscribed
    @oyster_supply_id = params[:oyster_supply]
    stream_from "supplies_channel_#{@oyster_supply_id}"
    add_user
  end

  def add_user
    @@state_data[@oyster_supply_id] ||= {}
    @@state_data[@oyster_supply_id][:users] ||= Set.new
    @@state_data[@oyster_supply_id][:sessions] ||= Set.new
    @@state_data[@oyster_supply_id][:users] << current_user.id
    @@state_data[@oyster_supply_id][:sessions] << params[:session_id]
  end

  def unsubscribed
    @@state_data[@oyster_supply_id][:users].delete(current_user.id)
    @@state_data[@oyster_supply_id][:sessions].delete(params[:session_id])
  end

  def update_users
    ActionCable.server.broadcast("supplies_channel_#{@oyster_supply_id}", { type: 'USERS', id: @oyster_supply_id, users: @@state_data[@oyster_supply_id][:users] })
  end

  def receive(data)
    @oyster_supply = OysterSupply.find(@oyster_supply_id)
    if data['type'] == 'INPUT_CHANGE'
      process_input_change(data)
    else
      ActionCable.server.broadcast("supplies_channel_#{@oyster_supply_id}", { type: 'DATA', data: data })
    end
  end

  def process_input_change(data)
      # "dig_point"=>"[\"large\",\"1\",\"1\"]"
      dig_point = JSON.parse(data['dig_point']) # ["am", "large", "1", "1"]
      nested_set(@oyster_supply.oysters, dig_point, data['value'])
      @oyster_supply.save

      ActionCable.server.broadcast("supplies_channel_#{@oyster_supply_id}", { type: 'INPUT_CHANGE', session_id: data['session_id'], user_id: current_user.id, selector: data['selector'], value: data['value'] })
  end

  def nested_set(hash, keys, value)
    last_key = keys.pop
    target = keys.inject(hash) { |h, key| h[key] ||= {} }
    target[last_key] = value
  end
end
