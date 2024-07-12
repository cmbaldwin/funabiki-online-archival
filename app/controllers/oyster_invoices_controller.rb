class OysterInvoicesController < ApplicationController
  before_action :set_oyster_invoice, only: %i[show edit update destroy force_send_mail]

  # GET /oyster_invoices
  # GET /oyster_invoices.json
  def index
    @oyster_invoices = OysterInvoice.search(params[:id]).paginate(page: params[:page], per_page: 8)
  end

  def new
    redirect_to oyster_supplies_path
  end

  def edit
    redirect_to oyster_supplies_path
  end

  # GET /oyster_invoices/1
  # GET /oyster_invoices/1.json
  def show
    redirect_to oyster_invoice_search_path(params[:id])
  end

  # POST /oyster_invoices
  # POST /oyster_invoices.json
  def create
    invoice = OysterInvoice.new(
      start_date: oyster_invoice_params[:start_date],
      end_date: oyster_invoice_params[:end_date],
      aioi_emails: oyster_invoice_params[:aioi_emails],
      sakoshi_emails: oyster_invoice_params[:sakoshi_emails],
      data: {
        passwords: {
          'sakoshi_all_password' => SecureRandom.hex(4).to_s,
          'sakoshi_seperated_password' => SecureRandom.hex(4).to_s,
          'aioi_all_password' => SecureRandom.hex(4).to_s,
          'aioi_seperated_password' => SecureRandom.hex(4).to_s
        },
        processing: true
      },
      completed: false,
      send_at: DateTime.strptime(oyster_invoice_params[:send_at], '%Y年%m月%d日 %H:%M')
    )
    invoice.oyster_supply_ids = invoice.date_range.map do |date|
      (supply = OysterSupply.find_by(supply_date: date.strftime('%Y年%m月%d日'))) ? supply.id : ()
    end
    if invoice.save
      message = Message.new(user: current_user.id, model: 'oyster_invoice', state: false, message: '牡蠣原料仕切り作成中…',
                            data: { invoice_id: invoice.id, expiration: (DateTime.now + 2.days) })
      message.save
      ProcessInvoiceWorker.perform_async(invoice.id, message.id)
      head :ok
    else
      respond_to do |format|
        format.html { redirect_to oyster_supplies_path, notice: invoice.errors.full_messages.each { |msg| msg + "\n" } }
        format.json { render json: invoice.errors, status: :unprocessable_entity }
      end
    end
  end

  def force_send_mail
    message = Message.new(user: current_user.id, model: 'send_invoice_mail', state: false,
                          message: "今すぐメールを送信中…",
                          data: {
                            invoice_id: @oyster_invoice.id,
                            expiration: (DateTime.now + 2.days)
                          })
    message.save
    MailerWorker.perform_async(@oyster_invoice.id, message.id)
    head :ok
  end

  # PATCH/PUT /oyster_invoices/1
  # PATCH/PUT /oyster_invoices/1.json
  def update
    new_params = oyster_invoice_params
    new_params[:send_at] =
      DateTime.strptime(oyster_invoice_params[:send_at], '%Y年%m月%d日 %H:%M').change(offset: '+0900')
    if new_params[:regenerate] == '1'
      regenerate
    else
      respond_to do |format|
        if @oyster_invoice.update(new_params)
          format.html { redirect_to @oyster_invoice, notice: '仕切りを更新しました。' }
          format.json { render :show, status: :ok, location: @oyster_invoice }
        else
          format.html { render :show }
          format.json { render json: @oyster_invoice.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  def regenerate
    @oyster_invoice.data = {
      passwords: {
        'sakoshi_all_password' => SecureRandom.hex(4).to_s,
        'sakoshi_seperated_password' => SecureRandom.hex(4).to_s,
        'aioi_all_password' => SecureRandom.hex(4).to_s,
        'aioi_seperated_password' => SecureRandom.hex(4).to_s
      },
      processing: true
    }
    @oyster_invoice.completed = false
    @oyster_invoice.save
    message = Message.new(user: current_user.id, model: 'oyster_invoice', state: false, message: '牡蠣原料仕切り作成中…',
                          data: { invoice_id: @oyster_invoice.id, expiration: (DateTime.now + 2.days) })
    message.save
    ProcessInvoiceWorker.perform_async(@oyster_invoice.id, message.id)
    head :ok
  end

  # DELETE /oyster_invoices/1
  # DELETE /oyster_invoices/1.json
  def destroy
    @oyster_invoice.destroy
    redirect_to oyster_supplies_path, notice: '仕切りを削除しました。'
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_oyster_invoice
    @oyster_invoice = OysterInvoice.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def oyster_invoice_params
    params.require(:oyster_invoice).permit(:start_date, :end_date, :aioi_all_pdf, :aioi_seperated_pdf,
                                           :sakoshi_all_pdf, :sakoshi_seperated_pdf, :completed,
                                           :aioi_emails, :sakoshi_emails, :data, :send_at, :regenerate)
  end
end
