all_data = Marshal.load(File.binread('./tmp/data_file_data.json.56670'))
all_data['/Users/danmayer/projects/coverband_demo/app/models/post.rb'][11]['caller_traces']
all_data['/Users/danmayer/projects/coverband_demo/app/models/post.rb'][11]['recent_bindings']
b = Binding.load(all_data['/Users/danmayer/projects/coverband_demo/app/models/post.rb'][11]['recent_bindings'].first)
b.pry # this part doesn't work

# this does
b.eval("local_variables")
b.local_variable_get(:posts)
b.local_variable_get(:bad_posts)
# change it
b.eval('bad_posts = posts.select { |post| true }')
b.local_variable_get(:bad_posts)
