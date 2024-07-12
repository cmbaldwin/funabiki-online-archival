class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :check_status

  def check_status
    return unless !current_user.approved? || current_user.supplier? || current_user.user?
    flash[:notice] = 'そのページはアクセスできません。'
    redirect_to root_path, error: 'そのページはアクセスできません。'
  end

  def admin?
    self.roles.include?(:admin)
  end

  def index

  end

  def show

  end

  def update
    @user.update(role: profit_params[:role])
    redirect_back(fallback_location: root_path)
    if @user.update(profit_params)
      flash[:notice] = '更新しました。'
    end
  end

  def destroy
    @user.destroy

    if @user.destroy
      flash[:notice] = '削除されました。'
      redirect_back(fallback_location: root_path)
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def profit_params
    params.require(:user).permit(:role, :id, :approved)
  end

end
