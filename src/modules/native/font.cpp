#include <stdio.h>
#include <neko.h>

#include <vector>
#include <algorithm>

#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_GLYPH_H
#include FT_OUTLINE_H

enum {
   PT_MOVE = 1,
   PT_LINE = 2,
   PT_CURVE = 3
};

struct point {
   int            x, y;
   unsigned char  type;

   point() { }
   point(int x, int y, unsigned char type) : x(x), y(y), type(type) { }
};

struct glyph {
   FT_ULong                char_code;
   FT_Vector               advance;
   FT_Glyph_Metrics        metrics;
   int                     index, x, y;
   std::vector<int>        pts;

   glyph(): x(0), y(0) { }
};

struct kerning {
   int                     l_glyph, r_glyph;
   int                     x, y;

   kerning() { }
   kerning(int l, int r, int x, int y): l_glyph(l), r_glyph(r), x(x), y(y) { }
};

struct glyph_sort_predicate {
   bool operator()(const glyph* g1, const glyph* g2) const {
      return g1->char_code <  g2->char_code;
   }
};

int outline_move_to(const FT_Vector *to, void *user) {
   glyph       *g = static_cast<glyph*>(user);

   g->pts.push_back(PT_MOVE);
   g->pts.push_back(to->x);
   g->pts.push_back(to->y);

   g->x = to->x;
   g->y = to->y;
   
   return 0;
}

int outline_line_to(const FT_Vector *to, void *user) {
   glyph       *g = static_cast<glyph*>(user);

   g->pts.push_back(PT_LINE);
   g->pts.push_back(to->x - g->x);
   g->pts.push_back(to->y - g->y);
   
   g->x = to->x;
   g->y = to->y;
   
   return 0;
}

int outline_conic_to(const FT_Vector *ctl, const FT_Vector *to, void *user) {
   glyph       *g = static_cast<glyph*>(user);

   g->pts.push_back(PT_CURVE);
   g->pts.push_back(ctl->x - g->x);
   g->pts.push_back(ctl->y - g->y);
   g->pts.push_back(to->x - ctl->x);
   g->pts.push_back(to->y - ctl->y);
   
   g->x = to->x;
   g->y = to->y;
   
   return 0;
}

int outline_cubic_to(const FT_Vector *ctl1, const FT_Vector *ctl2, const FT_Vector *to, void *user) {
   // Cubic curves are not supported
   return 1;
}

static FT_Library    ft;

value init() {
   int      result = FT_Init_FreeType(&ft);

   return alloc_bool(result == 0);
}

value import_font(value font_file, value char_vector, value em_size) {
   FT_Face           face;
   int               result, i, j;

   val_check(font_file, string);
   if(!val_is_null(char_vector))
      val_check(char_vector, array);
   val_check(em_size, int);

   result = FT_New_Face(ft, val_string(font_file), 0, &face);
   if (result == FT_Err_Unknown_File_Format) {
      val_throw(alloc_string("Unknown file format!"));
      return val_null;
   
   } else if(result != 0) {
      val_throw(alloc_string("File open error!"));
      return val_null;
   }

   if(!FT_IS_SCALABLE(face)) {
      FT_Done_Face(face);

      val_throw(alloc_string("Font is not scalable!"));
      return val_null;
   }

   int        em = val_int(em_size);
   FT_Set_Char_Size(face, em, em, 72, 72);

   std::vector<glyph*>     glyphs;

   FT_Outline_Funcs     ofn = {
      outline_move_to,
      outline_line_to,
      outline_conic_to,
      outline_cubic_to,
      0, // shift
      0  // delta
   };

   if(!val_is_null(char_vector)) {
      // Import only specified characters
      value       *cva = val_array_ptr(char_vector);
      int         num_char_codes = val_array_size(char_vector);

      for(i = 0; i < num_char_codes; i++) {
         FT_ULong    char_code = (FT_ULong)val_int(cva[i]);
         FT_UInt     glyph_index = FT_Get_Char_Index(face, char_code);

         if(glyph_index != 0 && FT_Load_Glyph(face, glyph_index, FT_LOAD_DEFAULT) == 0) {
            glyph             *g = new glyph;

            result = FT_Outline_Decompose(&face->glyph->outline, &ofn, g);
            if(result == 0) {
               g->index = glyph_index;
               g->char_code = char_code;
               g->metrics = face->glyph->metrics;
               glyphs.push_back(g);
            } else
               delete g;
         }
      }

   } else {
      // Import every character in face
      FT_ULong    char_code;
      FT_UInt     glyph_index;

      char_code = FT_Get_First_Char(face, &glyph_index);
      while(glyph_index != 0) {
         if(FT_Load_Glyph(face, glyph_index, FT_LOAD_DEFAULT) == 0) {
            glyph             *g = new glyph;

            result = FT_Outline_Decompose(&face->glyph->outline, &ofn, g);
            if(result == 0) {
               g->index = glyph_index;
               g->char_code = char_code;
               g->metrics = face->glyph->metrics;
               glyphs.push_back(g);
            } else
               delete g;
         }
         
         char_code = FT_Get_Next_Char(face, char_code, &glyph_index);  
      }
   }

   // Ascending sort by character codes
   std::sort(glyphs.begin(), glyphs.end(), glyph_sort_predicate());

   std::vector<kerning>      kern;
   if(FT_HAS_KERNING(face)) {
      int         n = glyphs.size();
      FT_Vector   v;

      for(i = 0; i < n; i++) {
         int      l_glyph = glyphs[i]->index;

         for(j = 0; j < n; j++) {
            int   r_glyph = glyphs[j]->index;

            FT_Get_Kerning(face, l_glyph, r_glyph, FT_KERNING_DEFAULT, &v);
            if(v.x != 0 || v.y != 0)
               kern.push_back( kerning(i, j, v.x, v.y) );
         }
      }
   }

   int               num_glyphs = glyphs.size();
   
   value             ret = alloc_object(NULL);
   alloc_field(ret, val_id("has_kerning"), alloc_bool(FT_HAS_KERNING(face)));
   alloc_field(ret, val_id("is_fixed_width"), alloc_bool(FT_IS_FIXED_WIDTH(face)));
   alloc_field(ret, val_id("has_glyph_names"), alloc_bool(FT_HAS_GLYPH_NAMES(face)));
   alloc_field(ret, val_id("is_italic"), alloc_bool(face->style_flags & FT_STYLE_FLAG_ITALIC));
   alloc_field(ret, val_id("is_bold"), alloc_bool(face->style_flags & FT_STYLE_FLAG_BOLD));
   alloc_field(ret, val_id("num_glyphs"), alloc_int(num_glyphs));
   alloc_field(ret, val_id("family_name"), alloc_string(face->family_name));
   alloc_field(ret, val_id("style_name"), alloc_string(face->style_name));
   alloc_field(ret, val_id("em_size"), alloc_int(face->units_per_EM));
   alloc_field(ret, val_id("ascend"), alloc_int(face->ascender));
   alloc_field(ret, val_id("descend"), alloc_int(face->descender));
   alloc_field(ret, val_id("height"), alloc_int(face->height));

   // 'glyphs' field
   value             neko_glyphs = alloc_array(num_glyphs);
   value             *nga = val_array_ptr(neko_glyphs);
   for(i = 0; i < glyphs.size(); i++) {
      glyph          *g = glyphs[i];
      int            num_points = g->pts.size();

      value          points = alloc_array(num_points);
      value          *pa = val_array_ptr(points);
      
      for(j = 0; j < num_points; j++)
         pa[j] = alloc_int(g->pts[j]);

      nga[i] = alloc_object(NULL);
      alloc_field(nga[i], val_id("char_code"), alloc_int(g->char_code));
      alloc_field(nga[i], val_id("advance"), alloc_int(g->metrics.horiAdvance));
      alloc_field(nga[i], val_id("min_x"), alloc_int(g->metrics.horiBearingX));
      alloc_field(nga[i], val_id("max_x"), alloc_int(g->metrics.horiBearingX + g->metrics.width));
      alloc_field(nga[i], val_id("min_y"), alloc_int(g->metrics.horiBearingY - g->metrics.height));
      alloc_field(nga[i], val_id("max_y"), alloc_int(g->metrics.horiBearingY));
      alloc_field(nga[i], val_id("points"), points);

      delete g;
   }
   alloc_field(ret, val_id("glyphs"), neko_glyphs);

   // 'kerning' field
   if(FT_HAS_KERNING(face)) {
      value       neko_kerning = alloc_array(kern.size());
      value       *nka = val_array_ptr(neko_kerning);

      for(i = 0; i < kern.size(); i++) {
         kerning  *k = &kern[i];

         nka[i] = alloc_object(NULL);
         alloc_field(nka[i], val_id("left_glyph"), alloc_int(k->l_glyph));
         alloc_field(nka[i], val_id("right_glyph"), alloc_int(k->r_glyph));
         alloc_field(nka[i], val_id("x"), alloc_int(k->x));
         alloc_field(nka[i], val_id("y"), alloc_int(k->y));
      }
      
      alloc_field(ret, val_id("kerning"), neko_kerning);
   } else
      alloc_field(ret, val_id("kerning"), val_null);

   FT_Done_Face(face);
   
   return ret;
}

DEFINE_PRIM(init, 0);
DEFINE_PRIM(import_font, 3);

