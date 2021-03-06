class Product < ApplicationRecord
  extend ActiveHash::Associations::ActiveRecordExtensions
  belongs_to_active_hash :prefecture
  belongs_to_active_hash :product_condition
  belongs_to_active_hash :postage_way
  belongs_to_active_hash :shipping_day
  belongs_to_active_hash :product_size
  has_many :product_images, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :favorites, dependent: :destroy
  belongs_to :seller, class_name: 'User', :foreign_key => 'seller_id'
  belongs_to :buyer, class_name: 'User', :foreign_key => 'buyer_id', optional: true
  belongs_to :product_category, optional: true
  belongs_to :product_brand, optional: true
  accepts_nested_attributes_for :product_images, allow_destroy: true

  #各項目のバリデーション
  with_options presence:true, if: :isProductPublicable?  do |v|
    v.validates :name
    v.validates :price, numericality: {greater_than_or_equal_to: 300, less_than_or_equal_to: 9999999}
    v.validates :description
    v.validates :product_category_id
    v.validates :product_condition_id
    v.validates :postage_way_id
    v.validates :shipping_day_id
    v.validates :prefecture_id
  end

  #文字数制限や価格のしきい値
  validates :name                 , length: { maximum: 40 }
  validates :description          , length: { maximum: 1000 }
  #画像枚数のバリデーション
  validates :product_images       , length: { maximum: 10}

  private
  
  def isProductPublicable?
    public_flag == 1
  end

end
