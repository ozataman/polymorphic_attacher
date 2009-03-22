module PolymorphicAttacher
  module ActiveRecordIncludes

    # Serializer method to turn the base_class and id into a string
    # for use in web forms and other forms of simple serialized communication
    def serialized_type_and_id
      return nil if new_record?
      "#{self.class.base_class.to_s}_#{self.id}"
    end
    
  end
  
end