class Brand < ActiveRecord::Base
	has_many :events
 
  def self.get_filters
    { brand: get_brand_codes }
  end

  def self.get_brand_codes
    codes = [] 
    results = Brand.select("id, brand_code")
    results.each do |brand|
      codes << {name: brand[:brand_code], value: brand[:id]}
    end
    codes
  end

end
