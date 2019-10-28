require_relative 'src/synchronizer'

run = Synchronizer.new

arg = ARGV.length == 0 ? 'all' : ARGV.first
case arg.downcase
when 'gms'
  run.gms
when 'gts'
  run.gts
when 'vts'
  run.vts
when 'gsi'
  run.gsi
when 'cts'
  run.cts
when 'wget'
  run.wget_pages
when 'all'
  while (true) do
    puts "=== " + run.datetime + " ==="
    begin
      run.wget_pages
      sleep 10
      run.gms
      run.gts
#      run.vts
#      run.gsi
      run.cts
    rescue
      puts "something wrong there"
    end
    
    puts run.datetime + " .. sleep 43200 seconds .."
    puts ""
    sleep 43200
  end
else
  "Unrecognized parameter: '#{arg}'"
end

