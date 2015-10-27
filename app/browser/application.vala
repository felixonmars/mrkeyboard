using WebKit;
using Gtk;
using Utils;
using Keymap;

namespace Application {
    const string app_name = "browser";
    const string dbus_name = "org.mrkeyboard.app.browser";
    const string dbus_path = "/org/mrkeyboard/app/browser";

    [DBus (name = "org.mrkeyboard.app.browser")]
    interface Client : Object {
        public abstract void create_window(string[] args, bool from_dbus) throws IOError;
    }

    [DBus (name = "org.mrkeyboard.app.browser")]
    public class ClientServer : Object {
        public virtual void create_window(string[] args, bool from_dbus=false) {
        }
    }

    public class Window : Interface.Window {
        public WebView webview;
        public ScrolledWindow scrolled_window;
        
        public Window(int width, int height, string bid, string path) {
            base(width, height, bid, path);
        }
        
        public override void init() {
            webview = new WebView();
            if (buffer_path.length == 0) {
                webview.load_uri("http://www.baidu.com");
            } else {
                webview.load_uri(buffer_path);
            }
            
            webview.title_changed.connect((source, frame, title) => {
                    rename_app_tab(mode_name, buffer_id, slice_string(title, 30), webview.get_uri());
                });
            webview.console_message.connect((message, line_number, source_id) => {
                    return true;
                });
            webview.new_window_policy_decision_requested.connect((view, frame, request, action, decision) => {
                    new_app_tab(app_name, request.get_uri());
                    
                    return false;
                });
            webview.key_press_event.connect((w, e) => {
                    string keyevent_name = Keymap.get_keyevent_name(e);
                    if (keyevent_name == "Alt + n") {
                        webview.go_back();
                    } else if (keyevent_name == "Alt + m") {
                        webview.go_forward();
                    } else if (keyevent_name == "Alt + r") {
                        webview.reload();
                    } else if (keyevent_name == "Alt + R") {
                        webview.reload_bypass_cache();
                    }
                    
                    return false;
                });
            webview.button_press_event.connect((w, e) => {
                    emit_button_press_event(e);
                    
                    return false;
                });
            
            scrolled_window = new ScrolledWindow(null, null);
            scrolled_window.add(webview);
            
            box.pack_start(scrolled_window, true, true, 0);
        }

        public override void scroll_vertical(bool scroll_up) {
            var vadj = scrolled_window.get_vadjustment();
            var value = vadj.get_value();
            var lower = vadj.get_lower();
            var upper = vadj.get_upper();
            var page_size = vadj.get_page_size();
            var scroll_offset = 50;  // avoid we can't read page continue when scroll page
            
            if (scroll_up) {
                vadj.set_value(double.min(value + (page_size - scroll_offset), upper - page_size));
            } else {
                vadj.set_value(double.max(value - (page_size - scroll_offset), lower));
            }
        }

        public override string get_mode_name() {
            return app_name;
        }
        
        public override Gdk.Window get_event_window() {
            return webview.get_window();
        }
    }

    public class CloneWindow : Interface.CloneWindow {
        public CloneWindow(int width, int height, int pwid, string mode_name, string bid, string path) {
            base(width, height, pwid, mode_name, bid, path);
        }
        
        public override string get_background_color() {
            return "white";
        }
    }
}