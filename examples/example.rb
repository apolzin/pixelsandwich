require '../pixelsandwich'

foo = PixelSandwich.new
foo.add_layer(:bike, :image, {:source_image => './black.jpg'})
foo.add_layer(:blabla, :text, {:words => "lalala\nlalalalalala", :size => 20, :gradient => ["FFFFFF","000000"]})
foo.add_layer(:logo, :image, {:source_image => './logo.png'})
foo.layers[:blabla].position = [20,20]
foo.layers[:logo].position = [80,120]
foo.file_name = "./whatever.jpg"
foo.render
