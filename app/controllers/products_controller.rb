class ProductsController < ApplicationController

  require "payjp"

  before_action :set_product_category_parent, only: :new
  before_action :card_present, only:[:credit_new, :credit_destroy, :purchase]
  # before_action :get_payjp_info
  before_action :set_api_key
  before_action :set_customer, only:[:purchase]
  before_action :set_card_information, only:[:purchase]
  before_action :take_card, only:[:purchase, :pay]
  before_action :get_product, only: [:show, :destroy, :credit_new, :credit_create, :credit_destroy, :purchase, :pay]

  def new
    @product = Product.new
  end

  def show
  end

  # 購入確認ページ
  def purchase
    @@product = Product.find(params[:id])
    if @card.present?
      @user = current_user
      @card = CreditCard.find_by(user_id: current_user.id)
      @card_brand = @card_information.brand
      case @card_brand
      when "Visa"
        @card_src = "visa.png"
      when "MasterCard"
        @card_src = "mastercard.png"
      when "JCB"
        @card_src = "JCB.png"
      when "American Express"
        @card_src = "AmericanExpress.png"
      when "Diners Club"
        @card_src = "DinersClub.png"
      when "Discover"
        @card_src = "DISCOVER.png"
      end
    end
    if current_user.destination
      @destination = Destination.find_by(user_id: current_user.id)
    end
  end

  ######################## ▼ クレジットカード関連 ▼ ########################
  # users_controllerにも記述あり

  # 新規作成
  def credit_new
    if @card.present?
      redirect_to action: "credit_show"
    else
      @card = CreditCard.new
    end
  end

  # 登録
  def credit_create
    customer = Payjp::Customer.create(card: params['payjp-token'], metadata: {user_id: current_user.id})
    @card = CreditCard.new(user_id: current_user.id, customer_id: customer.id, card_id: customer.default_card)
    if @card.save
      redirect_to purchase_product_path(@product.id)
    else
      redirect_to action: "credit_new"
    end
  end

  # 削除
  def credit_destroy
    @card = CreditCard.find_by(user_id: current_user.id)
    if @card.blank?
      redirect_to action: "credit_new"
    else
      if Rails.env == 'development'
        Payjp.api_key = ENV["PAYJP_PRIVATE_KEY"]
      else
        Payjp.api_key = Rails.application.credentials.payjp[:PAYJP_PRIVATE_KEY]
      end
      customer = Payjp::Customer.retrieve(@card.customer_id)
      customer.delete
      if @card.delete
        redirect_to purchase_product_path(@product.id), notice: "削除完了しました"
      else
        redirect_to purchase_product_path(@product.id), alert: "削除できませんでした"
      end
    end
  end
  ######################## ▲ クレジットカード関連 ▲ ########################

  # 購入
  def pay
    @card = CreditCard.where(user_id: current_user.id).first
    @destination = Destination.find_by(user_id: current_user.id)
    if @card.present? && @destination.present?
      charge = Payjp::Charge.create(
        amount: @product.price,
        customer: Payjp::Customer.retrieve(@card.customer_id),
        currency: 'jpy'
      )
      @product_buyer= Product.find(params[:id])
      @product_buyer.update(buyer_id: current_user.id)
      redirect_to purchased_product_path(current_user.id)
    else
      redirect_to purchase_product_path(@@product.id)
    end
  end

  def purchased
  end
  
  def destroy
    if @product.seller_id == current_user.id && @product.destroy
      redirect_to root_path
    else
      redirect_to product_path(@product)
    end
  end

  # 親カテゴリーに紐づく子カテゴリーの配列を取得
  def get_product_category_children
    @product_category_children = ProductCategory.find(params[:product_category_parent_name]).children
  end

  # 子カテゴリーに紐づく孫カテゴリーの配列を取得
  def get_product_category_grandchildren
    @product_category_grandchildren = ProductCategory.find("#{params[:product_category_child_id]}").children
  end

private

  # 親カテゴリーの配列を取得
  def set_product_category_parent  
    @product_category_parents = ProductCategory.where(ancestry: nil)
  end

  def product_params
    params.require(:product).permit(:name,:description,:price,:seller_id,:buyer_id,:product_category_id,:product_condition_id,:postage_way_id,:postage,:shipping_day_id,:product_brand_id,:product_size_id,:prefecture_id)
  end

  def card_present
    @card = CreditCard.where(user_id: current_user.id).first if CreditCard.where(user_id: current_user.id).present?
  end

  # def get_payjp_info
  #   if Rails.env == 'development'
  #     Payjp.api_key = ENV["PAYJP_PRIVATE_KEY"]
  #   else
  #     Payjp.api_key = Rails.application.credentials.payjp[:PAYJP_PRIVATE_KEY]
  #   end
  # end

  def set_api_key
    Payjp.api_key = Rails.application.credentials.payjp[:PAYJP_PRIVATE_KEY]
  end

  def set_customer
    if @card.present?
      @customer = Payjp::Customer.retrieve(@card.customer_id)
    end
  end

  def set_card_information
    if @card.present?
      @card_information = @customer.cards.retrieve(@card.card_id)
    end
  end

  def take_card
    @card = CreditCard.find_by(user_id: current_user.id)
  end

  def get_product
    @product = Product.find(params[:id])
  end
end
