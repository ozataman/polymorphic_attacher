module PolymorphicAttacher
    
  module ClassMethods
    class MissingConnectorDef < StandardError; end;
    
    def create_polymorphic_attacher_on(key, params={})
      params.assert_valid_keys([:find_scopes, :connector, :connector_source, :validate, :poly_getter])
      raise MissingConnectorDef, "need a connector" unless params[:connector]
      raise MissingConnectorDef, "need a connector source" unless params[:connector_source]
      
      key = key.to_s
      write_inheritable_attribute(:polymorphic_attachers, []) if read_inheritable_attribute(:polymorphic_attachers).nil?
      read_inheritable_attribute(:polymorphic_attachers) << params.merge({:key => key})
      
      include PolymorphicAttacher::InstanceMethods
          
      # provided key will serve as temporary storage
      attr_accessor key.to_sym
      
      connector = params.delete(:connector)
      connector_source = params.delete(:connector_source)
      if params.delete(:validate)
        validate "proper_#{key}_association".to_sym
      end
      
      before_validation :attach_polymorphic_associations
      
      if poly_getter = params.delete(:poly_getter)
        class_eval <<-HERE
          # convenience getter for the current collection of final association objects
          def #{poly_getter.to_s}(include_unsaved = true)
            collection = #{connector.to_s}.collect {|c| c.#{connector_source.to_s}}
            if include_unsaved
              collection += #{key}.to_a
            end
            collection
          end
        HERE
      end
            
      class_eval <<-HERE
        # delegative proxy setter
        def #{key}=(val)
          if val.is_a?(Array)
            val.each {|v| attach_polymorphic_to('#{key}', v)}
          else
            attach_polymorphic_to('#{key}', val)
          end
        end
                
        # ensure that there is at least one association
        def proper_#{key}_association
          errors.add('#{key}', :chosen) if @#{key}.blank? && #{connector}.blank?
        end
      HERE
      
    end
  end
  
  module InstanceMethods
    
    # Proxy setter to temporarily store the association
    # When provided from a web form, it is convenient to pass an ID string
    # Make sure type is in class form. Ex: GoodProduct_784573
    def attach_polymorphic_to(key, val)
      
      # turn key into an instance parameter
      key = "@#{key}" unless key.match("@")
      
      # initialize an empty array if the storage is nil
      instance_variable_set(key, []) if instance_variable_get(key).nil?
      
      if val.nil? || val.blank?
        # do nothing
      
      # if val is a string, then it must be in serialized record form
      elsif val.is_a?(String)
        type, record_id = val.split("_")
        klass = type.classify.constantize
        record_id = record_id.to_i
        instance_variable_get(key) << klass.current_tenant.find(record_id)
        
      # If an active record object has been provided directly, just accept it
      elsif val.class.respond_to?(:base_class) && val.class.base_class.descends_from_active_record?
        instance_variable_get(key) << val
      else
        raise ActiveRecord::MissingAttributeError, "#attach_polymorphic_to -> val needs to be a string or an ActiveRecord::Base descendant"
      end
    end
    
    # cycle through all associations that were defined and replace their new values
    # only works if there is a non-nil #key attribute set
    def attach_polymorphic_associations
      self.class.read_inheritable_attribute(:polymorphic_attachers).each do |attacher_hash|
        
        # get some variables for convenience
        key = attacher_hash[:key].to_sym
        source = attacher_hash[:connector_source].to_sym
        connector = attacher_hash[:connector].to_sym
        
        # if the proxy object is nil, don't touch associations
        return if self.send(key).nil?
        
        # reflect on the connector association to figure out a few implementation details
        klass = self.class.reflect_on_association(connector).klass
        as = self.class.reflect_on_association(connector).options[:as]
        
        # build the join-table objects that will establish the linkage
        collection = self.send(key).map {|record| klass.new(source => record, as => self)}
        
        # replace the old join-table object with the newly defined set
        self.send((attacher_hash[:connector] + "=").to_sym, collection)
      end
    end
    
  end
  
end