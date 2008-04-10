# Copyright (c) 2005 Thomas Fuchs
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# customized by Asa Hopkins, June 17, 2006

module ActionView
  module Helpers
    module SliderHelper

      # Creates a slider control out of an element.
      def slider_element(element_id, options={})
        prepare = "Element.cleanWhitespace('#{element_id}');"
        
        [:change, :slide].each do |k|
          if options.include?(k)
            name = 'on' + k.to_s.capitalize
            options[name] = "function(value){#{options[k]}}"
            options.delete k
           end
        end
        
        [:handles, :spans, :axis].each do |k|
          options[k] = array_or_string_for_javascript(options[k]) if options[k]
        end
        
        if options[:slider_value]
          options[:sliderValue] = array_or_numeric_for_javascript(options[:slider_value])
          options.delete :slider_value
        end
        
        if options[:values]
          options[:values] = array_for_javascript(options[:values])
        end

        options[:range] = "$R(#{options[:range].min},#{options[:range].max})" if options[:range]
        
        handle = options[:handles] || "$('#{element_id}').firstChild"
        options.delete :handles
                
        javascript_tag("#{prepare}new Control.Slider(#{handle},'#{element_id}', #{options_for_javascript(options)})")
      end
      
      # Creates a simple slider control and associates it with a hidden text field
      def slider_field(object, method, options={})
        options.merge!({ 
          :change => "$('#{object}_#{method}').value = value",
          :slider_value  => instance_variable_get("@#{object}").send(method)
        })
        hidden_field(object, method) <<        
        content_tag('div',content_tag('div', '', :class=>'grey_slider'), 
          :class => 'slider', :id => "#{object}_#{method}_slider") << 
        slider_element("#{object}_#{method}_slider", options)
      end
      
      def slider_stylesheet
        content_tag("style", <<-EOT
          div.slider {
            width: 150px;
            height: 5px;
            margin-top:5px;
            margin-bottom:5px;
            background: #ddd;
            position: relative;
          }
          div.slider div {
            position:absolute;
            width:8px;
            height:15px;
            margin-top:-5px;
            background: #999;
            border:1px outset white;
          }
        EOT
        )
      end
      
      def color_sliders(object, method, options={})
        tag = options[:tag]
        options.delete :tag
        to_return = ""
        
        red_method = method.to_s+'_red'
        red_method = red_method.to_sym
        value = instance_variable_get("@#{object}").color_web(tag,'red')
        #logger.debug value
        options.merge!({ 
          :range => 0..255,
          :change => "$('#{object}_#{red_method}').value = value",  
          :slider_value=>value
        })
        to_return << hidden_field(object, red_method,:value=>value) <<        
        content_tag('div',content_tag('div', '', :class=>'red_slider'), 
          :class => 'slider', :id => "#{object}_#{red_method}_slider") << 
        slider_element("#{object}_#{red_method}_slider", options)
        green_method = method.to_s+'_green'
        green_method = green_method.to_sym
        value = instance_variable_get("@#{object}").color_web(tag,'green')
        #logger.debug value
        options.merge!({ 
          :range => 0..255,
          :change => "$('#{object}_#{green_method}').value = value",  
          :slider_value=>value
        })
        to_return << hidden_field(object, green_method,:value=>value) <<
        content_tag('div',content_tag('div', '', :class=>'green_slider'), 
          :class => 'slider', :id => "#{object}_#{green_method}_slider") << 
        slider_element("#{object}_#{green_method}_slider", options)
        blue_method = method.to_s+'_blue'
        blue_method = blue_method.to_sym
        value = instance_variable_get("@#{object}").color_web(tag,'blue')
        #logger.debug value
        options.merge!({ 
          :range => 0..255,
          :change => "$('#{object}_#{blue_method}').value = value",  
          :slider_value=>value
        })
        to_return << hidden_field(object, blue_method,:value=>value) <<        
        content_tag('div',content_tag('div', '', :class=>'blue_slider'), 
          :class => 'slider', :id => "#{object}_#{blue_method}_slider") << 
        slider_element("#{object}_#{blue_method}_slider", options)
        return to_return
      end

      private
        def options_for_javascript(options)
          '{' + options.map {|k, v| "#{k}:#{v}"}.sort.join(', ') + '}'
        end

        def array_or_string_for_javascript(option)
          js_option = if option.kind_of?(Array)
            "['#{option.join('\',\'')}']"
          elsif !option.nil?
            "'#{option}'"
          end
          js_option
        end
        
        def array_or_numeric_for_javascript(option)
          js_option = if option.kind_of?(Array)
            "[#{option.join('\',\'')}]"
          elsif !option.nil?
            "#{option}"
          end
          js_option
        end

        def array_for_javascript(option)
          js_option = "[#{option.join(',')}]"
          js_option
        end

    end
  end
end