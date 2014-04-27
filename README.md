<img src="https://raw.github.com/Marxon13/M13AsynchronousImageView/master/ReadmeResources/M13AsynchronousImageViewBanner.png">

M13AsynchronousImageView
=============
M13AsynchronousImageView is a category extension of UIImageView that loads images asynchronously. Just pass the URL of the image, local or external, and the UIImageView will take care of loading the image in the background. This is perfect for UITableViews and UICollectionViews, as it doesn't block the main thread with image loading, so the main interface is still responsive.

Features:
-----------
* Loading images is simple, just pass the URL to the UIImageView with "loadImageAtURL:".
* Uses a custom class (M13AsynchronousImageLoader) to handle loading and storing the images. The image loader has a few options:
   * The image loader can handle local and external URLs.
   * There can be multiple image loaders with diffrent properties.
   * The loader uses the default NSCache. The NSCache property of the image loader is exposed to allow further refining of image caching properties.
   * The maximum number of concurrent downloads can be changed.
   * A custom timeout interval can be set.

Set Up:
--------------
* Unless a custom configuration is needed, there is no setup! Just start loading images.

Contact Me:
-------------
If you have any questions comments or suggestions, send me a message. If you find a bug, or want to submit a pull request, let me know.

License:
--------
MIT License

> Copyright (c) 2014 Brandon McQuilkin
> 
> Permission is hereby granted, free of charge, to any person obtaining 
>a copy of this software and associated documentation files (the  
>"Software"), to deal in the Software without restriction, including 
>without limitation the rights to use, copy, modify, merge, publish, 
>distribute, sublicense, and/or sell copies of the Software, and to 
>permit persons to whom the Software is furnished to do so, subject to  
>the following conditions:
> 
> The above copyright notice and this permission notice shall be 
>included in all copies or substantial portions of the Software.
> 
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
>EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
>MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
>IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
>CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
>TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
>SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.