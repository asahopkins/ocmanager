class Object

  def c(*args, &block)
    EZ::Where::Condition.new(*args, &block)
  end
  
  def to_c
    self.c + self
  end
    
end

module EZ

  module Where
    # EZ::Condition plugin for generating the :conditions where clause
    # for ActiveRecord::Base.find. And an extension to ActiveRecord::Base
    # called AR::Base.find_with_conditions that takes a block and builds
    # the where clause dynamically for you.
    
    class Condition
	    
	    ACTION_CONTROLLER_RESERVED = %w{ request params cookies session }
	    
	    # need this so that id doesn't call Object#id
	    # left it open to add more methods that
	    # conflict when I find them
	    [:id, :type].each { |m| undef_method m }
      
      # these are also reserved words regarding SQL column names
      # use esc_* prefix to circumvent any issues
      attr_reader :clauses      
      attr_accessor :inner
      attr_accessor :outer
            
      # Initialize @clauses and eval the block so 
      # it invokes method_missing.
      def initialize(*args, &block)
        options = args.last.is_a?(Hash) ? args.pop : {}
        options[:table_name] = args.first if args.first.kind_of?(Symbol) || args.first.kind_of?(String) || args.first.respond_to?(:table_name)
        @table_name = (name = options.delete(:table_name) || nil).respond_to?(:table_name) ? name.table_name : name
        @outer = options.delete(:outer) || :and
        @inner = options.delete(:inner) || :and
        @parenthesis = options.delete(:parenthesis)
        @clauses = []
        if block_given? 
          @context_binding = block.binding  
          instance_eval(&block)
        end
      end   

      # When invoked with the name of the column in each statement inside the block: 
      # A new Clause instance is created and recieves the args. Then the operator
      # hits method_missing and gets sent to a new Clause instance where it either 
      # matches one of the defined ops or hits method_missing there.
      #
      # When invoked with an attached block a subcondition is created. The name
      # is regarded as the table_name, additional parameters for outer and inner
      # are passed on. 
      def method_missing(name, *args, &block)
        if ACTION_CONTROLLER_RESERVED.include?(reserved = name.to_s) 
          return eval(reserved, @context_binding)
        end    
        if block_given?         
          # handle name as table_name and create a subcondition
          options = args.last.is_a?(Hash) ? args.last : {}
          options[:table_name] ||= name
          define_sub(options, &block)
        else
          clause(name, *args)
        end
      end
      
      # Override Object.c to return instance similar to self or
      # new instance if args given
      def create_condition(*args, &block)
        if args.empty?
          newcond = self.dup.reset_clauses
        else
          newcond = EZ::Where::Condition.new(*args)
        end
        newcond.instance_eval(&block) if block_given? 
        newcond
      end
      alias :c :create_condition
      
      # Reset clauses
      def reset_clauses
        @clauses = []
        self
      end
      
      # You can define clauses dynamicly using this method. It will take a 
      # clause and create the correct Clause object to process the conditions
      def clause(name, *args)
        if name.kind_of?(Array)
          clause = Clause.new(name.first, name.last)
        elsif args.last.kind_of?(Symbol)
          clause = Clause.new(args.pop, name)
        else 
          clause = Clause.new(@table_name, name)
        end
        @clauses << clause
        clause
      end
      
      # You can define clauses dynamicly using this method. It will take a 
      # column name, operator (Symbol or String) and the matching value
      def create_clause(name, operator, value, case_insensitive = false)
        clause = clause(name)
        clause.case_insensitive if case_insensitive
        clause.send(operator.to_sym, value)
      end
      
      # You can match several columns using the same operator and value using :or
      def any_clause(*names)
        clause = MultiClause.new(names, @table_name, :or)
        @clauses << clause
        clause       
      end
      
      alias :any_of :any_clause
      
      # You can match several columns using the same operator and value using :and
      def all_clause(*names)
        clause = MultiClause.new(names, @table_name, :and)
        @clauses << clause
        clause
      end
      
      alias :all_of :all_clause
      
      # Create subcondition from a block, optionally specifying table_name, outer and inner.
      # :outer determines how the subcondition is added to the condition, while :inner 
      # determines the internal 'joining' of conditions inside the subcondition. Both
      # :inner & :outer default to 'AND'
      def define_sub(*args, &block)
        options = args.last.is_a?(Hash) ? args.last : {}
        options[:table_name] = args.first if args.first.kind_of? Symbol
        options[:table_name] ||= @table_name
        cond = Condition.new(options, &block)
        self << cond
      end
      
      # Aliases for syntax convenience. :sub or :condition map to :define_sub
      alias :sub :define_sub
      alias :condition :define_sub
            
      # Shortcut for adding a :and boolean joined subcondition        
      def and_condition(*args, &block)
        options = args.last.is_a?(Hash) ? args.last : {}
        options[:table_name] = args.first if args.first.kind_of? Symbol
        options[:outer] ||= @outer
        options[:inner] ||= :and
        define_sub(options, &block)
      end

      # Alias :all to be shorthand for :and_condition
      alias :all :and_condition

      # Shortcut for adding a :or boolean joined subcondition  
      def or_condition(*args, &block)
        options = args.last.is_a?(Hash) ? args.last : {}
        options[:table_name] = args.first if args.first.kind_of? Symbol
        options[:outer] ||= @outer
        options[:inner] ||= :or
        define_sub(options, &block)
      end

      # Alias :any to stand in for :or_condition
      alias :any :or_condition

      # Append a condition element, which can be one of the following:
      # - String: raw sql string
      # - ActiveRecord instance, for attribute or PK cloning
      # - ActiveRecord Class, sets inheritance column for STI 
      # - Condition or Clause with to_sql method and outer property
      # - Array in ActiveRecord format ['column = ?', 2]
      # - Hash { :column_a => 'value', :column_b => 'othervalue' }
      def <<(condition, outer = nil)        
        is_ez_where = condition.kind_of?(Condition) || (condition.kind_of?(AbstractClause) and not condition.empty?)
        condition = condition.to_cond if condition.respond_to?(:to_cond) && !is_ez_where and !condition.kind_of?(Hash)
        if condition.kind_of?(String) and not condition.to_s.empty? 
          cond = SqlClause.new(condition)
          cond.outer = outer || :and      
          @clauses << cond unless cond.empty?                            
        else          
          if condition.kind_of?(Condition) || (condition.kind_of?(AbstractClause) and not condition.empty?) # check again
            logic = condition.outer if outer.nil?
            condition = condition.to_sql 
          elsif condition.kind_of?(Hash)
            condition = condition.to_conditions
            logic = outer
          else
            logic = outer
          end
          if condition.kind_of?(Array) and not condition.empty?
            array_clause = ArrayClause.new(condition)
            array_clause.outer = logic
            @clauses << array_clause
          end
        end       
      end
      
      # Aliases for :<<, the method itself deals with what kind
      # of condition you are appending to the chain so these 
      # aliases are for a nicer syntax's sake.
      alias :sql_condition :<<      
      alias :add_sql :<<
      alias :clone_from :<<
      alias :append :<<
      alias :combine :<<
      
      def compose(cond, type = :and)
        newcond = EZ::Where::Condition.new(:inner => type)
        newcond.append(self)
        newcond.append(cond, type) 
        newcond 
      end
      
      def +(cond) 
        compose(cond, :and)    
      end
      
      def -(cond)
        compose(cond, :not) 
      end
      
      def |(cond)
        compose(cond, :or)     
      end
                       
      # Loop over all Clause objects in @clauses array
      # and call to_sql on each instance. Then join
      # the queries and params into the :conditions
      # array with logic defaulting to AND.
      # Subqueries are joined together using their 
      # individual outer property setting if present.
      # Also defaults to AND.
      def to_sql(logic = nil, parenthesis = nil)
        logic = logic.nil? ? @inner : logic
        parenthesis = parenthesis.nil? ? @parenthesis : parenthesis
        params = []; query = []
        @clauses.each do |cv|
          next if cv.empty?
          sql = cv.to_sql 
          qs = sql.shift
          par = sql.first.kind_of?(Array) ? sql.first : sql               
          logic_s = cv.outer ? cv.outer : logic
          logic_s = logic_s.to_s.upcase
          logic_s = 'AND NOT' if logic_s == 'NOT'
          query << logic_s unless query.empty?
          query << qs
          if cv.test == :in 
            params << par if par.respond_to?(:map)
          elsif par.kind_of?(Array)
            par.flatten! unless qs =~ /IN/
            params += par
          else
  	        params << par unless par.nil?
  	      end      	           
        end
        cond = query.join(' ') 
        return nil if cond.to_s.empty?  
        cond = "(#{cond})" if parenthesis
        [cond, *params]
      end
    
    end

  end # EZ module

end # Caboose module