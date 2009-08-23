#include <neko.h>
#include <magick/MagickCore.h>
#include <wand/MagickWand.h>

#ifdef _MSC_VER
typedef unsigned __int32 uint32_t;
#else
#include <stdint.h>
#endif

#include <set>

extern "C" value init() {
   MagickWandGenesis();

   return alloc_bool(true);
}

extern "C" value image_info(value image_file) {
   MagickWand           *wand = NewMagickWand();
   MagickBooleanType    result;

   result = MagickReadImage(wand, (const char*)val_string(image_file));
   if (result == MagickFalse) {
      ExceptionType           e_type;
      char                    *e_text;

      e_text = MagickGetException(wand, &e_type);
      DestroyMagickWand(wand);
      val_throw(alloc_string(e_text));
   }

   int                  width = MagickGetImageWidth(wand);
   int                  height = MagickGetImageHeight(wand);

   value                ret = alloc_object(NULL);
   alloc_field(ret, val_id("width"), alloc_int(width));
   alloc_field(ret, val_id("height"), alloc_int(height));

   DestroyMagickWand(wand);

   return ret;
}

extern "C" value import_image(value image_file) {
   MagickWand           *wand = NewMagickWand();
   MagickBooleanType    result;

   result = MagickReadImage(wand, (const char*)val_string(image_file));
   if (result == MagickFalse) {
      ExceptionType           e_type;
      char                    *e_text;

      e_text = MagickGetException(wand, &e_type);
      DestroyMagickWand(wand);
      val_throw(alloc_string(e_text));
   }

   Image                *img = GetImageFromMagickWand(wand);
   int                  width = MagickGetImageWidth(wand);
   int                  height = MagickGetImageHeight(wand);
   int                  img_size;
   unsigned char        *img_data;
   int                  bpp;

   int                  i;
   int                  pixels;
   unsigned char        *argb_data;
   std::set<uint32_t>   color_set;
   uint32_t             *col;

   value                ret = alloc_object(NULL);
   alloc_field(ret, val_id("width"), alloc_int(width));
   alloc_field(ret, val_id("height"), alloc_int(height));

   pixels = width * height;
   argb_data = new unsigned char[pixels * 4];
   MagickGetImagePixels(wand, 0, 0, width, height, "ARGB", CharPixel, argb_data);

   // Try to build palette
   col = (uint32_t*)argb_data;
   for (i = 0; color_set.size() <= 256 && i < pixels; i++)
      color_set.insert(*col++);

   if (color_set.size() <= 256) {
      // Create colormapped image
      int            colors = color_set.size();
      unsigned char  *palette, *indices;
      int            row_padding = (4 - (width & 3)) & 3;

      img_size = colors * 4 + (width + row_padding) * height;
      img_data = new unsigned char[img_size];
      bpp = 8;

      palette = img_data;
      indices = img_data + colors * 4;

      // Store palette
      std::set<uint32_t>::iterator        ci, ci_end;
      for (ci = color_set.begin(), ci_end = color_set.end(); ci != ci_end; ci++) {
         uint32_t          color = *ci;
         int               alpha = color & 0xff;

         palette[0] = ((color >> 8)  & 0xff) * alpha / 255;
         palette[1] = ((color >> 16) & 0xff) * alpha / 255;
         palette[2] = ((color >> 24) & 0xff) * alpha / 255;
         palette[3] = alpha;

         palette += 4;
      }

      // Store image
      int            j;

      col = (uint32_t*)argb_data;
      ci = color_set.begin();
      for (i = 0; i < height; i++) {
         for (j = 0; j < width; j++) {
            *indices++ = std::distance(ci, color_set.find(*col++));
         }

         indices += row_padding;
      }

      delete[] argb_data;

   } else {
      // Create truecolor image
      img_size = pixels * 4;
      img_data = argb_data;
      bpp = 32;

      int      img_type = MagickGetImageType(wand);

      if (img_type == GrayscaleType || img_type == PaletteType || img_type == TrueColorType) {
         // No alpha channel so every alpha value in argb_data will be zero. I love you ImageMagick...
         for (i = 0; i < pixels; i++) {
            argb_data[0] = 255;
            argb_data += 4;
         }
      } else {
         // Premultiply with alpha
         for (i = 0; i < pixels; i++) {
            argb_data[1] = argb_data[1] * argb_data[0] / 255;
            argb_data[2] = argb_data[2] * argb_data[0] / 255;
            argb_data[3] = argb_data[3] * argb_data[0] / 255;
            argb_data += 4;
         }
      }
   }
   DestroyMagickWand(wand);

   alloc_field(ret, val_id("bits"), alloc_int(bpp));
   alloc_field(ret, val_id("data"), copy_string((const char*)img_data, img_size));

   delete[] img_data;

   return ret;
}

extern "C" value import_mask(value image_file) {
   MagickWand           *wand = NewMagickWand();
   MagickBooleanType    result;

   result = MagickReadImage(wand, (const char*)val_string(image_file));
   if (result == MagickFalse) {
      ExceptionType           e_type;
      char                    *e_text;

      e_text = MagickGetException(wand, &e_type);
      DestroyMagickWand(wand);
      val_throw(alloc_string(e_text));
   }

   int                  width = MagickGetImageWidth(wand);
   int                  height = MagickGetImageHeight(wand);

   value                ret = alloc_object(NULL);
   alloc_field(ret, val_id("width"), alloc_int(width));
   alloc_field(ret, val_id("height"), alloc_int(height));

   unsigned char        *mask = new unsigned char[width * height];
   MagickGetImagePixels(wand, 0, 0, width, height, "I", CharPixel, mask);
   DestroyMagickWand(wand);

   alloc_field(ret, val_id("data"), copy_string((const char*)mask, width * height));

   delete[] mask;

   return ret;

}

DEFINE_PRIM(init, 0);
DEFINE_PRIM(image_info, 1);
DEFINE_PRIM(import_image, 1);
DEFINE_PRIM(import_mask, 1);

