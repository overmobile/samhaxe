# Installation

## Installing precompiled binaries (Win32 only)

Precompiled binaries for the latest release are available
[here](https://github.com/overmobile/samhaxe/releases/tag/1.0)

### Dependencies

SamHaXe depends on some additional software to do its job.  To use the
precompiled Win32 binary you will need the following software installed on your
system:

- [FreeType 2](http://sourceforge.net/projects/freetype/files/)
- [ImageMagick](http://www.imagemagick.org/script/binary-releases.php#windows)
- ... or ... - (depending on your choice of binary)
- [DevIL](http://openil.sourceforge.net/download.php)

#### Configuring FreeType

Assuming you have FreeType installed under `C:\Program Files\FreeType2`, you need to add the following path to the PATH environment variable:

- `C:\Program Files\FreeType2\bin`

#### Configuring ImageMagick

ImageMagick binaries are available [here](https://github.com/overmobile/samhaxe/releases/download/1.0/samhaxe-1.0-mojito-current-win32-ImageMagick.zip).

Assuming you have installed ImageMagick under `C:\Program Files\ImageMagick`, you need to add the following paths to the PATH environment variable:

- `C:\Program Files\ImageMagick`
- `C:\Program Files\ImageMagick\modules`

## Building from source

### Required software

SamHaXe depends on HaXe version 2 to work. Most likely, you would need to
compile it from source.

The full list of dependencies follows:

- [HaXe compiler v2.10](https://github.com/overmobile/haxe-2.10)
- [Neko virtual with C dev package](http://nekovm.org/download)
- Some supported C/C++ sompiler suite - GCC, MinGW or VisualStudio
- [ImageMagick with C/C++ dev package](http://www.imagemagick.org/script/binary-releases.php)
- [DevIL with C/C++ dev package](http://openil.sourceforge.net/download.php)
- [FreeType 2 with C/C++ dev package](http://sourceforge.net/projects/freetype/files/)
- [Apache Ant 1.7 or better](http://ant.apache.org/bindownload.cgi)
- (optional) [NaturalDocs](http://www.naturaldocs.org/download.html)

### Build configuration

Copy `config.ant.sample` as `config.ant` and edit the latter, specifying paths to your installation.

On OS X, relevant configuration items look like the following:

    ## HaXe
    haxe.path=/opt/haxe-2-10
    haxe.stdpath=/opt/haxe-2-10/std

    # ImageMagick
    imagemagick.path=/usr/local/Cellar/imagemagick/6.8.8-9
    imagemagick.include.path=/usr/local/Cellar/imagemagick/6.8.8-9/include/ImageMagick-6
    imagemagick.library.name=MagickWand-6.Q16
    imagemagick.library.path=${imagemagick.path}/lib

    ## Neko configuration
    neko.path=/usr/local/lib/neko
    neko.include.path=${neko.path}/include
    neko.library.path=${neko.path}

    ## FreeType2 configuration
    freetype.path=/usr/X11
    freetype.include.path=${freetype.path}/include
    freetype.library.path=${freetype.path}/lib

    ## Base installation path
    install.path=/opt/samhaxe

For more options, consult `config.ant.sample`.

### Building and installing

To compile and install SamHaxe under the directory you specified as `install.path`, run

    ant clean install

### Running

    SamHaxe -h # show usage
    SamHaxe input.xml output.swf # assemble an SWF
