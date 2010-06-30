#include <neko.h>
#include <IL/il.h>
#include <IL/ilu.h>

#include <string.h> /* for memcpy */

#include <set>

extern "C" value init() {
   ilInit();
   iluInit();

   return alloc_bool(true);
}

extern "C" value image_info(value image_file) {
   ILuint               img;
   
   ilGenImages(1, &img);
   ilBindImage(img);

   if(ilLoadImage((char*)val_string(image_file))) {
      value                ret = alloc_object(NULL);

      alloc_field(ret, val_id("width"), alloc_int(ilGetInteger(IL_IMAGE_WIDTH)));
      alloc_field(ret, val_id("height"), alloc_int(ilGetInteger(IL_IMAGE_HEIGHT)));

      ilDeleteImages(1, &img);

      return ret;

   } else {
      ilDeleteImages(1, &img);
      
      val_throw(alloc_string(iluErrorString(ilGetError())));
   }
}

extern "C" value import_image(value image_file) {
   ILuint               img;
   
   ilGenImages(1, &img);
   ilBindImage(img);

   if(!ilLoadImage((char*)val_string(image_file))) {
      ilDeleteImages(1, &img);
      val_throw(alloc_string(iluErrorString(ilGetError())));
   }

   int            width = ilGetInteger(IL_IMAGE_WIDTH);
   int            height = ilGetInteger(IL_IMAGE_HEIGHT);
   bool           palette;
   bool           alpha;
   int            format = ilGetInteger(IL_IMAGE_FORMAT);
   unsigned char  *img_data;
   int            img_size;
   int            bpp;

   switch(format) {
      case IL_COLOR_INDEX:
         palette = true;
         
         switch(ilGetInteger(IL_PALETTE_TYPE)) {
            case IL_PAL_NONE:
               ilDeleteImages(1, &img);
               val_throw(alloc_string("Indexed image without palette"));
               break;
            
            case IL_PAL_BGRA32:
               ilConvertPal(IL_PAL_RGBA32);

            case IL_PAL_RGBA32:
               alpha = true;
               break;

            case IL_PAL_BGR24:
            case IL_PAL_RGB32:
            case IL_PAL_BGR32:
               ilConvertPal(IL_PAL_RGB24);

            case IL_PAL_RGB24:
               alpha = false;
               break;
         }
         break;

      case IL_LUMINANCE:
      case IL_BGR:
      case IL_RGB:
         if(format != IL_RGB || ilGetInteger(IL_IMAGE_TYPE) != IL_UNSIGNED_BYTE)
            ilConvertImage(IL_RGB, IL_UNSIGNED_BYTE);

         palette = false;
         alpha = false;
         break;

      case IL_LUMINANCE_ALPHA:
      case IL_BGRA:
      case IL_RGBA:
         if(format != IL_RGBA || ilGetInteger(IL_IMAGE_TYPE) != IL_UNSIGNED_BYTE)
            ilConvertImage(IL_RGBA, IL_UNSIGNED_BYTE);

         palette = false;
         alpha = true;
         break;
   }
   
   if(palette) {
      // Create colormapped image
      int            i;
      int            colors = ilGetInteger(IL_PALETTE_NUM_COLS);
      unsigned char  *palette, *indices;
      int            row_padding = (4 - (width & 3)) & 3;
      int            bpc = alpha ? 4 : 3;

      img_size = colors * bpc + (width + row_padding) * height;
      img_data = new unsigned char[img_size];
      bpp = 8;

      palette = img_data;
      indices = img_data + colors * bpc;
      
      // Store palette
      ILubyte        *il_pal = ilGetPalette();
      if(alpha) {
         // RGBA palette
         for (i = 0; i < colors; i++) {
            long        alpha = il_pal[3];

            // Premultiply with alpha
            palette[0] = (long)il_pal[0] * alpha / 255; // R
            palette[1] = (long)il_pal[1] * alpha / 255; // G
            palette[2] = (long)il_pal[2] * alpha / 255; // B
            palette[3] = alpha;                         // A

            palette += 4;
            il_pal += 4;
         }

      } else {
         // RGB palette
         for (i = 0; i < colors; i++) {
            palette[0] = il_pal[0]; // R
            palette[1] = il_pal[1]; // G
            palette[2] = il_pal[2]; // B

            palette += 3;
            il_pal += 3;
         }
      }

      // Store image
      ILubyte        *il_data = ilGetData();
      for (i = 0; i < height; i++) {
         memcpy(indices, il_data, width);
         indices += width + row_padding;
         il_data += width;
      }

   } else {
      // Create 0RGB / ARGB image
      int            i, j;

      img_size = (width * height) << 2;
      img_data = new unsigned char[img_size];
      bpp = alpha ? 32 : 24;

      // Store image
      ILubyte        *il_data = ilGetData();
      unsigned char  *p = img_data;
      if(alpha) {
         // Store ARGB image
         for(j = 0; j < height; j++) {
            for(i = 0; i < width; i++) {
               int         alpha = il_data[3];
         
               // Premultiply with alpha
               p[0] = alpha;                    // A
               p[1] = il_data[0] * alpha / 255; // R
               p[2] = il_data[1] * alpha / 255; // G
               p[3] = il_data[2] * alpha / 255; // B

               p += 4;
               il_data += 4;
            }
            // ARGB is always 32bit aligned so no additional shift
            // is applied on p
         }

      } else {
         // Store 0RGB image
         for(j = 0; j < height; j++) {
            for(i = 0; i < width; i++) {
               // Alpha is always 0 in RGB data
               p[0] = 0;          // A
               p[1] = il_data[0]; // R
               p[2] = il_data[1]; // G
               p[3] = il_data[2]; // B

               p += 4;
               il_data += 3;
            }
            // 0RGB is always 32bit aligned so no additional shift
            // is applied on p
         }
      }
   }

   value                ret = alloc_object(NULL);
   alloc_field(ret, val_id("width"), alloc_int(width));
   alloc_field(ret, val_id("height"), alloc_int(height));
   alloc_field(ret, val_id("alpha"), alloc_bool(alpha));

   if(palette)
      alloc_field(ret, val_id("colors"), alloc_int(ilGetInteger(IL_PALETTE_NUM_COLS)));
   
   alloc_field(ret, val_id("bits"), alloc_int(bpp));
   alloc_field(ret, val_id("data"), copy_string((const char*)img_data, img_size));

   delete[] img_data;
   ilDeleteImages(1, &img);

   return ret;
}

extern "C" value import_mask(value image_file) {
   ILuint               img;
   
   ilGenImages(1, &img);
   ilBindImage(img);

   if(!ilLoadImage((char*)val_string(image_file))) {
      ilDeleteImages(1, &img);
      val_throw(alloc_string(iluErrorString(ilGetError())));
   }

   ilConvertImage(IL_LUMINANCE, IL_UNSIGNED_BYTE);

   int            width = ilGetInteger(IL_IMAGE_WIDTH);
   int            height = ilGetInteger(IL_IMAGE_HEIGHT);

   value                ret = alloc_object(NULL);
   alloc_field(ret, val_id("width"), alloc_int(width));
   alloc_field(ret, val_id("height"), alloc_int(height));

   unsigned char        *mask = new unsigned char[width * height];

   ilCopyPixels(0, 0, 0, width, height, 1, IL_LUMINANCE, IL_UNSIGNED_BYTE, mask);

   alloc_field(ret, val_id("data"), copy_string((const char*)mask, width * height));

   delete[] mask;
   ilDeleteImages(1, &img);

   return ret;

}

DEFINE_PRIM(init, 0);
DEFINE_PRIM(image_info, 1);
DEFINE_PRIM(import_image, 1);
DEFINE_PRIM(import_mask, 1);

