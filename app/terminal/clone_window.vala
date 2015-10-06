using Gtk;
using GtkClutter;
using ClutterX11;
using Clutter;

namespace Application {
    public class CloneWindow : Gtk.Window {
        public string mode_name = "terminal";
        public int window_id;
        public ClutterX11.TexturePixmap texture;
        
        public signal void create_app(int app_win_id, string mode_name, int tab_id);
        
        public CloneWindow(int width, int height, int tab_id, int parent_window_id) {
            set_decorated(false);
            set_default_size(width, height);

            var embed = new GtkClutter.Embed();
            add(embed);
    
            texture = new ClutterX11.TexturePixmap.with_window(parent_window_id);
            texture.set_automatic(true);
            
            var stage = embed.get_stage();
            stage.set_background_color(Color.from_string("black"));
            stage.add_child(texture);
            
            realize.connect((w) => {
                    var xid = (int)((Gdk.X11.Window) get_window()).get_xid();
                    window_id = xid;
                    create_app(window_id, mode_name, tab_id);
                });
        }
        
        public void update_texture() {
            Gtk.Allocation alloc;
            get_allocation(out alloc);
            
            texture.update_area(0, 0, alloc.width, alloc.height);
        }
    }
}