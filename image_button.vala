using Cairo;
using Draw;
using Gtk;

namespace Widgets {
    public class ImageButton : Gtk.Button {
        Cairo.ImageSurface normal_surface;
        Cairo.ImageSurface hover_surface;
        Cairo.ImageSurface press_surface;
        
        public ImageButton(string image_path) {
            normal_surface = new Cairo.ImageSurface.from_png("image/" + image_path + "_normal.png");
            hover_surface = new Cairo.ImageSurface.from_png("image/" + image_path + "_hover.png");
            press_surface = new Cairo.ImageSurface.from_png("image/" + image_path + "_press.png");
            
            set_size_request(this.normal_surface.get_width(), this.normal_surface.get_height());
            
            this.draw.connect(on_draw);
        }
        
        private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            var state_flags = widget.get_state_flags();
            
            if (state_flags == Gtk.StateFlags.PRELIGHT) {
                Draw.draw_surface(cr, hover_surface);
            } else if (state_flags == Gtk.StateFlags.ACTIVE) {
                Draw.draw_surface(cr, press_surface);
            } else {
                Draw.draw_surface(cr, normal_surface);                
            }
            
            return true;
        }
    }
}