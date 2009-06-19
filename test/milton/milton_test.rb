require File.dirname(__FILE__) + '/../test_helper'

class MiltonTest < ActiveSupport::TestCase
  context "running a syscall" do
    should "return false on failure" do
      assert !Milton.syscall('ls this_directory_definitely_doesnt_exist')
    end
    
    should "return output on success" do
      assert_equal "foo\n", Milton.syscall("echo foo")
    end
  end
  
  context "running a syscall!" do
    should "raise a Milton::SyscallFailedError if it fails" do
      assert_raise Milton::SyscallFailedError do
        Milton.syscall!('ls this_directory_definitely_doesnt_exist')
      end
    end
  end
end
