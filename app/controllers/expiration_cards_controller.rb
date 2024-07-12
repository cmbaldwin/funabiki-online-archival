class ExpirationCardsController < ApplicationController
  before_action :set_expiration_card
  before_action :check_status

  def check_status
    return unless !current_user.approved? || current_user.supplier? || current_user.employee? || current_user.user?

    flash[:notice] = 'そのページはアクセスできません。'
    redirect_to root_path, error: 'そのページはアクセスできません。'
  end

  # GET /expiration_cards
  # GET /expiration_cards.json
  def index
    @expiration_cards = ExpirationCard.all.order(:created_at).reverse
  end

  # GET /expiration_cards/1
  # GET /expiration_cards/1.json
  def show; end

  # GET /expiration_cards/new
  def new; end

  # GET /expiration_cards/1/edit
  def edit; end

  def regenerate
    message = Message.new(user: current_user.id, model: 'expiration_card', state: false,
                          message: "#{Time.zone.today.to_date}のセルカードを作成中…", data: { expiration: (DateTime.now + 12.hours) })
    message.save
    ExpirationRegenerationWorker.perform_async(message.id)
    head :ok
  end

  def set_shomiorhi(card, params)
    params[:shomiorhi].to_i.zero? ? (card.shomiorhi = false) : (card.shomiorhi = true)
  end

  # POST /expiration_cards
  # POST /expiration_cards.json
  def create
    if ExpirationCard.exists?(expiration_card_params)
      respond_to do |format|
        format.html { redirect_to @expiration_card.find(expiration_card_params), notice: 'このカードはもう作られた。' }
        format.json { render :show, status: :ok, location: @expiration_card }
      end
    else
      @expiration_card = ExpirationCard.new(expiration_card_params)
      set_shomiorhi(@expiration_card, expiration_card_params)
      @expiration_card.create_pdf

      respond_to do |format|
        if @expiration_card.save
          format.html { redirect_to @expiration_card, notice: '賞味期限カードを作成しました。' }
          format.json { render :show, status: :created, location: @expiration_card }
        else
          format.html { render :new }
          format.json { render json: @expiration_card.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # PATCH/PUT /expiration_cards/1
  # PATCH/PUT /expiration_cards/1.json
  def update
    if @expiration_card.file.attached?
      @expiration_card.file.purge
      @expiration_card.update(expiration_card_params)
      set_shomiorhi(@expiration_card, expiration_card_params)
      @expiration_card.create_pdf
      respond_to do |format|
        if @expiration_card.update(expiration_card_params)
          format.html { redirect_to @expiration_card, notice: '賞味期限カードを編集しました。' }
          format.json { render :show, status: :ok, location: @expiration_card }
        else
          format.html { render :edit }
          format.json { render json: @expiration_card.errors, status: :unprocessable_entity }
        end
      end
    else
      destroy
    end
  end

  # DELETE /expiration_cards/1
  # DELETE /expiration_cards/1.json
  def destroy
    @expiration_card.file&.purge
    @expiration_card.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@expiration_card) }
      format.html { redirect_to expiration_cards_url, notice: '賞味期限カードを削除しました。' }
      format.json { head :no_content }
    end
  end

  def download
    if @expiration_card.file.attached?
      send_data @expiration_card.file.download,
                filename: @expiration_card.file.blob.filename.to_s,
                type: 'application/pdf',
                disposition: 'inline'
    else
      redirect_to expiration_cards_path, alert: 'ファイルが見つかりません。'
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_expiration_card
    @expiration_card = if params[:id]
                         ExpirationCard.find(params[:id])
                       else
                         ExpirationCard.new(new_params)
                       end
  end

  def new_params
    params.permit(:product_name, :manufacturer_address, :manufacturer, :ingredient_source, :storage_recommendation,
                  :consumption_restrictions, :manufactuered_date, :expiration_date, :made_on, :shomiorhi)
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def expiration_card_params
    params.require(:expiration_card).permit(:product_name, :manufacturer_address, :manufacturer, :ingredient_source,
                                            :storage_recommendation, :consumption_restrictions, :manufactuered_date, :expiration_date, :made_on, :shomiorhi)
  end
end
