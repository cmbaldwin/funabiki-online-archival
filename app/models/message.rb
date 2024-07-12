class Message < ApplicationRecord
  before_save :set_dismissed
  after_create :prepend
  after_update :replace
  after_destroy :remove

  has_one_attached :stored_file

  mount_uploader :document, MessageDocumentUploader

  validates :user, presence: true
  validates :model, presence: true
  validates :message, presence: true

  serialize :data, type: Hash

  def set_dismissed
    data ||= {}
    data[:dismissed] ||= false
  end

  def dismissed
    set_dismissed
    data[:dismissed]
  end

  def prepend
    broadcast('prepend')
  end

  def replace
    broadcast('replace')
  end

  def remove
    broadcast('remove')
  end

  def broadcast(action)
    ActionCable.server.broadcast "messages_channel_#{user}", { id:, action: action }
  end

  def status
    return :error if state.nil?

    state ? :completed : :processing
  end

  def border
    return 'border-danger' if status == :error

    status == :processing ? 'border-warning' : 'border-success'
  end
end
