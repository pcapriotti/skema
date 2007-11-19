mkdir -p "<%= File.join(@install_prefix, 'bin') %>"
cp -a ../skema.rb "<%= File.join(@install_prefix, 'bin/skema') %>" 
cp -a skemarc "<%= File.join(ENV['HOME'], '.skemarc') %>" 
mkdir -p "<%= File.join(@install_prefix, 'share/skema') %>"
cp -a ../gpl "<%= File.join(@install_prefix, 'share/skema/') %>"
cp -a ../kapp "<%= File.join(@install_prefix, 'share/skema/') %>"

