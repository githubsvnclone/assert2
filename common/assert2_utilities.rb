require 'test/unit/assertions'

module Test; module Unit; module Assertions

  def add_diagnostic(whatever)
    @__additional_diagnostics ||= []
    
    if whatever == :clear
      @__additional_diagnostics = []
    else
      @__additional_diagnostics << whatever if whatever
    end
  end

end