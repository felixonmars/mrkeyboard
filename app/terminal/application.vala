using Vte;
using Gtk;

namespace Application {
    const string app_name = "terminal";
    const string dbus_name = "org.mrkeyboard.app.terminal";
    const string dbus_path = "/org/mrkeyboard/app/terminal";

    [DBus (name = "org.mrkeyboard.app.terminal")]
    interface Client : Object {
        public abstract void create_window(string[] args, bool from_dbus) throws IOError;
    }

    [DBus (name = "org.mrkeyboard.app.terminal")]
    public class ClientServer : Object {
        public virtual void create_window(string[] args, bool from_dbus=false) {
        }
    }

    public class Window : Interface.Window {
        public Vte.Terminal term;
        public GLib.Pid process_id;
        
        public Window(int width, int height, int tid, string bid) {
            base(width, height, tid, bid);
        }
        
        public override void init() {
            term = new Terminal();
            term.child_exited.connect((t) => {
                    close_app_tab(mode_name, buffer_id);
                });
            term.window_title_changed.connect((t) => {
                    string working_directory;
                    string[] spawn_args = {"readlink", "/proc/%i/cwd".printf(process_id)};
                    try {
                        Process.spawn_sync(null, spawn_args, null, SpawnFlags.SEARCH_PATH, null, out working_directory);
                    } catch (SpawnError e) {
                        print("Got error when spawn_sync: %s\n", e.message);
                    }
                    
                    if (working_directory.length > 0) {
                        working_directory = working_directory[0:working_directory.length - 1];
                        if (buffer_name != working_directory) {
                            var paths = working_directory.split("/");
                            rename_app_tab(mode_name, buffer_id, paths[paths.length - 1]);
                            buffer_name = working_directory;
                        }
                    }
                });
            var arguments = new string[0];
            var shell = get_shell();
            try {
                GLib.Shell.parse_argv(shell, out arguments);
            } catch (GLib.ShellError e) {
                print("Got error when get_shell: %s\n", e.message);
            }
            try {
                term.fork_command_full(PtyFlags.DEFAULT, null, arguments, null, SpawnFlags.SEARCH_PATH, null, out process_id);
            } catch (GLib.Error e) {
                print("Got error when fork_command_full: %s\n", e.message);
            }
            box.pack_start(term, true, true, 0);
        }        
        
        public override string get_mode_name() {
            return app_name;
        }
        
        public override Gdk.Window get_event_window() {
            return term.get_window();
        }
        
        private static string get_shell() {
            string? shell = Vte.get_user_shell();
        
            if (shell == null) {
                shell = "/bin/sh";
            }
        
            return (!)(shell);
        }
    }

    public class CloneWindow : Interface.CloneWindow {
        public CloneWindow(int width, int height, int tid, int pwid, string mode_name, string bid) {
            base(width, height, tid, pwid, mode_name, bid);
        }
        
        public override string get_background_color() {
            return "black";
        }
    }
}