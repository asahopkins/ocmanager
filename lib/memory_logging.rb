module MemoryLogging
  def self.included(controller)
    controller.after_filter :log_mem_stat  if ENV['RAILS_ENV']=='production'
  end

  private

  def log_mem_stat
    if File.exists?("/proc/self/status")
      vm_info = File.read("/proc/self/status").grep(/^Vm(RSS|Size)/).map{|l| 
        l.chomp.gsub(/\t/, ' ').gsub(/ +/, ' ')
      }
      rss, size = vm_info.map{|l| l.scan(/\d+/).first.to_i}
      info = "PID #{$$}, #{vm_info.join(', ')}"
      info << ", Size Diff #{rss - $vm_rss} kB" if $vm_rss
      info << ", RSS Diff #{size - $vm_size} kB" if $vm_size
      logger.info "Virtual Memory #{self.class.name}##{action_name} (#{info})"
      $vm_rss, $vm_size = rss, size
    end
  end
end