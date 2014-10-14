# SamHaxe

SamHaXe -- a flash resource assembly tool

## Installation

Precompiled binaries for Win32 are available in the
[Releases](https://github.com/overmobile/samhaxe/releases) section.

Installing SamHaXe from source can get somewhat tricky. See
[INSTALL.md](https://github.com/overmobile/samhaxe/blob/master/INSTALL.md) for
detailed instructions.

## Usage

Let's suppose you'd like to package an image 'image1.png' and a sound file
'sound1.mp3' for you awesome game.

First, create a file `assets.xml`, containing the following XML describing the
assets you are going to package:

```xml
<?xml version="1.0" encoding="utf-8"?>

<shx:resources version="9" compress="true" package=""
   xmlns:shx="http://mindless-labs.com/samhaxe"
   xmlns:img="http://mindless-labs.com/samhaxe/modules/Image"
   xmlns:snd="http://mindless-labs.com/samhaxe/modules/Sound">
   xmlns:font="http://mindless-labs.com/samhaxe/modules/Font">

   <shx:frame>
      <img:image import="image1.png" class="image1" />
      <snd:sound import="sound1.mp3" class="sound1" />
   </shx:frame>
</shx:resources>
```

Then, feed `assets.xml` to SamHaxe and get the SWF as output:

    SamHaXe assets.xml assets.swf

## Credits

This project is a fork of https://github.com/robinp/samhaxe-open. The great
folks there did all the work. This repository only contains minor fixes
intended to make SamHaXe buildable again on recent systems.

## Contributing

Send pull requests and issues to the parent project,
https://github.com/robinp/samhaxe-open.
