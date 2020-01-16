#!/usr/bin/env ruby

line_num=0
text=File.open('st.txt').read

text.each_line do |line|
  line = line.gsub(' ','\ ').gsub('&','\\\&').gsub('(','\(').gsub(')','\)')
  puts "===================================================file"
  puts line
  puts "===================================================file"
  system("ruby testlink_import_test_case_systemtest.rb #{line}")
end
