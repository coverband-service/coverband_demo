###
# This file is an example of how we detect files that aren't ever loaded by the app or used in runtime, to mark for deletion
###
class UnreachablePoro
  raise "what what loaded this file"
  def self.my_class_is_no_longer_needed
    puts "if you can get here in code, please tell me how"
    raise "wat, how did that happen?"
  end
end
