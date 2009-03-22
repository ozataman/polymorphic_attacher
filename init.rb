require 'polymorphic_attacher'
require 'active_record_includes'

ActiveRecord::Base.send(:extend, PolymorphicAttacher::ClassMethods)
ActiveRecord::Base.send(:include, PolymorphicAttacher::ActiveRecordIncludes)