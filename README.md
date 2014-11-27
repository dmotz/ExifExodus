[![ExifExodus](http://exifexodus.com/assets/images/logo.svg)](http://exifexodus.com)

### Remove EXIF/GPS data from your photos before you upload them.

[Dan Motzenbecker](http://oxism.com), MIT License

[@dcmotz](http://twitter.com/dcmotz)


## What is EXIF?
[EXIF](http://en.wikipedia.org/wiki/Exchangeable_image_file_format)
is a type of metadata that is embedded in photo files from most types
of cameras and phones.

This metadata includes information about the device used to capture the photo,
but also often includes the GPS coordinates of where the photo was taken.

Many users unknowingly share this information with the general public
and site/app owners when uploading photos online.

This has been a common vector of privacy lapses, including cases where
journalists have unintentionally published photos with geotagging data intact.

Recent press has also revealed the NSA&rsquo;s collection of EXIF data in
its [XKeyscore](http://en.wikipedia.org/wiki/XKeyscore) program.


## What is ExifExodus?
ExifExodus is a small piece of
[open-source code](https://github.com/dmotz/ExifExodus) that
runs directly in your browser and strips EXIF data out of your photos before
you upload them.


## How does it work?
You can run ExifExodus whenever you&rsquo;re uploading photos by using its
bookmarklet (available on the [site](http://exifexodus.com))

When ExifExodus encounters a JPG file, it will remove the EXIF data by
copying the pixels to a new image file, similar to taking a screenshot of
something.

Alternatively, you can drop your files in the dropzone at the top of the
[site](http://exifexodus.com)) and receive versions free of EXIF data. You can
then save these new files and upload them wherever you&rsquo;d like.


## Is EXIF without merit?
That&rsquo;s certainly not the implication of this project. Metadata adds
another dimension to photos and is valuable for preserving context.
This project aims to educate and give users a choice in the matter of sharing
it with specific services (and the web at large).


## Doesn&rsquo;t Facebook (etc.) remove EXIF data before displaying photos?
Yes. Although this prevents the general public from accessing your EXIF data,
you should be aware that the end recipient is free to use or store the metadata
before removing it.


## Any caveats?
The ExifExodus bookmarklet won&rsquo;t work with any site that uses Flash
(or any other proprietary plugins like Silverlight) to upload files.
For such sites, use the dropzone converter, save the output files, and upload
those instead.

ExifExodus only works with JPG files (which is the most common image
format to carry EXIF metadata).


## Who made this?
Dan Motzenbecker

[oxism.com](http://oxism.com)

[@dcmotz](https://twitter.com/dcmotz)

[github/dmotz](https://github.com/dmotz)

