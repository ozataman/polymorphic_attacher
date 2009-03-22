class WeirdPerson < ActiveRecord::Base
  has_many :thing_connectors, :as => :owner, :class_name => "WeirdnessConnector"
  has_many :pijamas, :through => :thing_connectors, :source => :thing, :source_type => "Pijama"
  has_many :slippers, :through => :thing_connectors, :source => :thing, :source_type => "Slipper"
end
  
  
class Pijamas < ActiveRecord::Base
  
end

class Slippers < ActiveRecord::Base
  
end

class WeirdnessConnector < ActiveRecord::Base
  belongs_to :owner, :polymorhpic => true
  belongs_to :thing, :polymorhpic => true
end