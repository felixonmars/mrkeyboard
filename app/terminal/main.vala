using Gtk;
using Vte;
using GLib;
using Gdk;
using Application;
using Gee;

[DBus (name = "org.mrkeyboard.Daemon")]
interface Daemon : Object {
    public abstract void send_app_tab_info(int app_win_id, string mode_name, int tab_id) throws IOError;
    public signal void send_key_event(int window_id, uint key_val, int key_state, uint32 key_time, bool press);
    public signal void hide_window(int window_id);
    public signal void show_window(int window_id);
}

[DBus (name = "org.mrkeyboard.app.terminal")]
public class ClientServer : Object {
    private ArrayList<Application.Window> window_list;
    private Daemon daemon;
    
    public int init(string[] args) {
        if (GtkClutter.init(ref args) != Clutter.InitError.SUCCESS) {
            return -1;
        }
        
        try {
            daemon = Bus.get_proxy_sync(BusType.SESSION, "org.mrkeyboard.Daemon",
                                                        "/org/mrkeyboard/daemon");
        
            daemon.send_key_event.connect((focus_window, key_val, key_state, key_time, press) => {
                    handle_send_key_event(focus_window, key_val, key_state, key_time, press);
                });
            daemon.hide_window.connect((hide_window_id) => {
                    handle_hide(hide_window_id);
                });
            daemon.show_window.connect((show_window_id) => {
                    handle_show(show_window_id);
                });
        } catch (IOError e) {
            stderr.printf("%s\n", e.message);
        }    
        
        window_list = new ArrayList<Application.Window>();
        create_window(args);
        
        Gtk.main();
        
        return 0;
    }
    
    public void create_window(string[] args) {
        var width = int.parse(args[1]);
        var height = int.parse(args[2]);
        var tab_id = int.parse(args[3]);
        
        var window = new Application.Window(width, height, tab_id);
        window.create_app.connect((app_win_id, mode_name, tab_id) => {
                try {
                    daemon.send_app_tab_info(app_win_id, mode_name, tab_id);
                } catch (IOError e) {
                    stderr.printf("%s\n", e.message);
                }
            });
        window.show_all();
        window_list.add(window);
    }
    
    private void handle_send_key_event(int window_id, uint key_val, int key_state, uint32 key_time, bool press) {
        var window = get_match_window(window_id);
        if (window != null) {
            window.handle_key_event(key_val, key_state, key_time, press);
        }
    }
    
    private void handle_hide(int window_id) {
        var window = get_match_window(window_id);
        if (window != null) {
            window.hide();
        }
    }
    
    private void handle_show(int window_id) {
        var window = get_match_window(window_id);
        if (window != null) {
            window.show();
        }
    }
    
    private Application.Window? get_match_window(int window_id) {
        foreach (Application.Window window in window_list) {
            if (window_id == window.window_id) {
                return window;
            }
        }
        
        return null;
    }
}

[DBus (name = "org.mrkeyboard.app.terminal")]
interface Client : Object {
    public abstract void create_window(string[] args) throws IOError;
}

void on_bus_aquired(DBusConnection conn, ClientServer client_server) {
    try {
        conn.register_object("/org/mrkeyboard/app/terminal", client_server);
    } catch (IOError e) {
        stderr.printf("Could not register service\n");
    }
}

int main(string[] args) {
    var client_server = new ClientServer();
    
    Bus.own_name(BusType.SESSION,
                 "org.mrkeyboard.app.terminal",
                 BusNameOwnerFlags.NONE,
                 ((con) => {on_bus_aquired(con, client_server);}),
                 () => {},
                 () => {
                     Client client = null;
                     
                     try {
                         client = Bus.get_proxy_sync(BusType.SESSION, "org.mrkeyboard.app.terminal", "/org/mrkeyboard/app/terminal");
                         client.create_window(args);
                     } catch (IOError e) {
                         stderr.printf("%s\n", e.message);
                     }
                     
                     Gtk.main_quit();
                 });

    client_server.init(args);
    
    return 0;
}

