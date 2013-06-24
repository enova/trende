module LabelHelper

  def labels
    labels_hash = {
      "fast_food" => {
                  "primary_attribute" => "Restaurant",
                  "secondary_attribute" => "Secondary",
                  "lower_bound" => "Min",
                  "upper_bound" => "Max",
                  "type" => "Type",
                  "brand" => "Brand"
                }
    }
    labels_hash.default = {
                "primary_attribute" => "Primary",
                "secondary_attribute" => "Secondary",
                "lower_bound" => "Min",
                "upper_bound" => "Max",
                "type" => "Type",
                "brand" => "Brand"
    }
    labels_hash
  end

  def get_label(type, key)
    labels[type.to_s][key.to_s]
  end

end
