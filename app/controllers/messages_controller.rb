class MessagesController < ApplicationController
  before_action :set_message, only: %i[show refresh content destroy]

  def index
    @messages = Message.where(user: current_user.id)
    respond_to do |format|
      format.turbo_stream { render 'messages/index' }
    end
  end

  def show
    # Message was destroyed
    return head :no_content unless @message

    @action = params[:turbo_action]
    respond_to do |format|
      format.turbo_stream { render 'messages/show' }
    end
  end

  def refresh
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(@message, partial: 'messages/message', locals: { message: @message })
      end
      format.html { render partial: 'messages/message', locals: { message: @message }, layout: false }
    end
  end

  def content
    respond_to do |format|
      format.html { render partial: 'messages/content', locals: { message: @message }, layout: false }
    end
  end

  # DELETE /message/1
  def destroy
    @id = @message.id
    @message.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@message) }
      format.html { redirect_to messages_url, notice: 'Message was successfully destroyed.' }
    end
  end

  # GET /message/1/download
  def download
    message = Message.find(params[:id])
    if message.stored_file.attached?
      send_data message.stored_file.download,
                filename: message.stored_file.filename.to_s,
                type: message.stored_file.content_type,
                disposition: 'inline'
    else
      redirect_to root_path, alert: 'ファイルが見つかりませんでした。'
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_message
    @message = Message.find_by(id: params[:id])
  end

  def message_params
    params.permit(:id, :user, :model, :document, :stored_file, :message, :state, :created_at, :updated_at)
  end
end
