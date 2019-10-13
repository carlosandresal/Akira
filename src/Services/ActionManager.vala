/*
* Copyright (c) 2019 Alecaddd (http://alecaddd.com)
*
* This file is part of Akira.
*
* Akira is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* Akira is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with Akira.  If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/

public class Akira.Services.ActionManager : Object {
    public weak Akira.Application app { get; construct; }
    public weak Akira.Window window { get; construct; }

    public SimpleActionGroup actions { get; construct; }

    public const string ACTION_PREFIX = "win.";
    public const string ACTION_NEW_WINDOW = "action_new_window";
    public const string ACTION_OPEN = "action_open";
    public const string ACTION_SAVE = "action_save";
    public const string ACTION_SAVE_AS = "action_save_as";
    public const string ACTION_SHOW_PIXEL_GRID = "action-show-pixel-grid";
    public const string ACTION_SHOW_UI_GRID = "action-show-ui-grid";
    public const string ACTION_PRESENTATION = "action_presentation";
    public const string ACTION_PREFERENCES = "action_preferences";
    public const string ACTION_EXPORT = "action_export";
    public const string ACTION_QUIT = "action_quit";
    public const string ACTION_ZOOM_IN = "action_zoom_in";
    public const string ACTION_ZOOM_OUT = "action_zoom_out";
    public const string ACTION_ZOOM_RESET = "action_zoom_reset";
    public const string ACTION_RECT_TOOL = "action_rect_tool";
    public const string ACTION_ELLIPSE_TOOL = "action_ellipse_tool";
    public const string ACTION_TEXT_TOOL = "action_text_tool";
    public const string ACTION_SELECTION_TOOL = "action_selection_tool";
    public const string ACTION_DELETE = "action_delete";

    public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

    GLib.File? file;

    private const ActionEntry[] ACTION_ENTRIES = {
        { ACTION_NEW_WINDOW, action_new_window },
        { ACTION_OPEN, action_open },
        { ACTION_SAVE, action_save },
        { ACTION_SAVE_AS, action_save_as },
        { ACTION_SHOW_PIXEL_GRID, action_show_pixel_grid },
        { ACTION_SHOW_UI_GRID, action_show_ui_grid },
        { ACTION_PRESENTATION, action_presentation },
        { ACTION_PREFERENCES, action_preferences },
        { ACTION_EXPORT, action_export },
        { ACTION_QUIT, action_quit },
        { ACTION_ZOOM_IN, action_zoom_in },
        { ACTION_ZOOM_OUT, action_zoom_out },
        { ACTION_ZOOM_RESET, action_zoom_reset },
        { ACTION_RECT_TOOL, action_rect_tool },
        { ACTION_ELLIPSE_TOOL, action_ellipse_tool },
        { ACTION_TEXT_TOOL, action_text_tool },
        { ACTION_SELECTION_TOOL, action_selection_tool },
        { ACTION_DELETE, action_delete },
    };

    public ActionManager (Akira.Application akira_app, Akira.Window window) {
        Object (
            app: akira_app,
            window: window
        );
    }

    static construct {
        action_accelerators.set (ACTION_NEW_WINDOW, "<Control>n");
        action_accelerators.set (ACTION_OPEN, "<Control>o");
        action_accelerators.set (ACTION_SAVE, "<Control>s");
        action_accelerators.set (ACTION_SAVE_AS, "<Control><Shift>s");
        action_accelerators.set (ACTION_SHOW_PIXEL_GRID, "<Control><Shift>p");
        action_accelerators.set (ACTION_SHOW_UI_GRID, "<Control><Shift>g");
        action_accelerators.set (ACTION_PRESENTATION, "<Control>period");
        action_accelerators.set (ACTION_PREFERENCES, "<Control>comma");
        action_accelerators.set (ACTION_EXPORT, "<Control><Shift>e");
        action_accelerators.set (ACTION_QUIT, "<Control>q");
        action_accelerators.set (ACTION_ZOOM_IN, "<Control>plus");
        action_accelerators.set (ACTION_ZOOM_OUT, "<Control>minus");
        action_accelerators.set (ACTION_ZOOM_RESET, "<Control>0");
    }

    construct {
        actions = new SimpleActionGroup ();
        actions.add_action_entries (ACTION_ENTRIES, this);
        window.insert_action_group ("win", actions);

        foreach (var action in action_accelerators.get_keys ()) {
            app.set_accels_for_action (ACTION_PREFIX + action, action_accelerators[action].to_array ());
        }
    }

    private void action_quit () {
        window.before_destroy ();
    }

    private void action_presentation () {
        window.headerbar.toggle ();
        window.main_window.left_sidebar.toggle ();
        window.main_window.right_sidebar.toggle ();
    }

    private void action_new_window () {
        app.new_window ();
    }

    private void action_open () {
        var open_dialog = new Gtk.FileChooserNative ("Open file",
                                                     this as Gtk.Window,
                                                     Gtk.FileChooserAction.OPEN,
                                                     "Open", "Cancel");
        add_filters (open_dialog);
        open_dialog.local_only = false; //allow for uri
        open_dialog.set_modal (true);
        open_dialog.response.connect (open_response_cb);
        open_dialog.show ();
    }

    void open_response_cb (Gtk.NativeDialog dialog, int response_id) {
        var open_dialog = dialog as Gtk.FileChooserNative;

        switch (response_id) {
            case Gtk.ResponseType.ACCEPT:
                file = open_dialog.get_file();

                uint8[] file_contents;

                try {
                    file.load_contents (null, out file_contents, null);
                }
                catch (GLib.Error err) {
                    error ("%s\n", err.message);
                }
                Json.Parser parser = new Json.Parser ();
                parser.load_from_data ((string) file_contents);

                //TODO: You need to register names to be disoverable by name
                Type? type_rect = typeof (Goo.CanvasRect);
                Type? type_ellipse = typeof (Goo.CanvasEllipse);
                Type? type_text = typeof (Goo.CanvasText);

                Json.Node node = parser.get_root ();
                var root_object_node = node.get_object ();
                Json.Array array = root_object_node.get_member ("items").get_array ();
                var canvas = window.main_window.main_canvas.canvas;
                foreach (unowned Json.Node node_item in array.get_elements ()) {
                    var object_node = node_item.get_object ();
                    load_item (object_node);
                }
                var scale = root_object_node.get_double_member ("scale");
                canvas.set_scale (scale);
                //TODO: listen to scale on canvas to change the zoom_button
                window.headerbar.zoom.zoom_default_button.label = "%.0f%%".printf (scale * 100);

                print ("opened: %s\n", (open_dialog.get_filename ()));
                break;

            case Gtk.ResponseType.CANCEL:
                print ("cancelled: FileChooserAction.OPEN\n");
                break;
        }
        dialog.destroy ();
    }

    void load_item (Json.Object object_node) {
        var canvas = window.main_window.main_canvas.canvas;
        string type = object_node.get_string_member ("type");
        var object_node_item = object_node.get_member ("item");
        Goo.CanvasItem item = Json.gobject_deserialize (Type.from_name (type), object_node_item) as Goo.CanvasItem;
        if (item != null) {
            item.set("parent", canvas.get_root_item ());
            var object_node_transform = object_node.get_member ("transform").get_object ();
            var transform = Cairo.Matrix.identity ();
            transform.xx = object_node_transform.get_double_member ("xx");
            transform.xy = object_node_transform.get_double_member ("xy");
            transform.yx = object_node_transform.get_double_member ("yx");
            transform.yy = object_node_transform.get_double_member ("yy");
            transform.x0 = object_node_transform.get_double_member ("x0");
            transform.y0 = object_node_transform.get_double_member ("y0");
            item.set_transform (transform);
            add_artboard_layer (item, type.replace ("GooCanvas", ""));
        }
    }

    void add_artboard_layer (Goo.CanvasItem item, string type) {
        if (type == "Rect") {
            type = "Rectangle";
        } else if (type == "Ellipse") {
            type = "Circle";
        }
        var artboard = window.main_window.right_sidebar.layers_panel.artboard;
        var layer = new Akira.Layouts.Partials.Layer (window, artboard, (Goo.CanvasItemSimple)item,
            type, "shape-" + type.down () + "-symbolic", false);
        item.set_data<Akira.Layouts.Partials.Layer?> ("layer", layer);
        artboard.container.add (layer);
        artboard.show_all ();
    }

    private void action_save (SimpleAction action, Variant? parameter) {
        if (file != null) {
            this.save_to_file ();
        }
        else {
            action_save_as (action, parameter);
        }
    }

    void save_as_response_cb (Gtk.NativeDialog dialog, int response_id) {
        var save_dialog = dialog as Gtk.FileChooserDialog;

        switch (response_id) {
            case Gtk.ResponseType.ACCEPT:
                file = save_dialog.get_file();
                this.save_to_file ();
                break;
            default:
                break;
        }
            dialog.destroy ();
    }

    void save_to_file () {
        var canvas = window.main_window.main_canvas.canvas;
        var root_item = canvas.get_root_item ();

        Json.Builder builder = new Json.Builder ();

        builder.begin_object ();
        builder.set_member_name ("version");
        builder.add_string_value ("1.0");

        builder.set_member_name ("scale");
        builder.add_double_value (canvas.get_scale ());

        builder.set_member_name ("items");
        builder.begin_array ();
        for (int i = 0; i < root_item.get_n_children (); i++) {
           Goo.CanvasItem item = root_item.get_child(i);
           if (item.get_data<bool>("ignore")) {
               continue;
           }
           Json.Node node = Json.gobject_serialize (item);
           builder.begin_object ();
           builder.set_member_name ("type");
           builder.add_string_value (item.get_type ().name ());
           builder.set_member_name ("item");
           builder.add_value (node);
           var transform = Cairo.Matrix.identity ();
           item.get_transform (out transform);
           builder.set_member_name ("transform");
           builder.begin_object ();
           builder.set_member_name("xx");
           builder.add_double_value(transform.xx);
           builder.set_member_name("yx");
           builder.add_double_value(transform.yx);
           builder.set_member_name("xy");
           builder.add_double_value(transform.xy);
           builder.set_member_name("yy");
           builder.add_double_value(transform.yy);
           builder.set_member_name("x0");
           builder.add_double_value(transform.x0);
           builder.set_member_name("y0");
           builder.add_double_value(transform.y0);
           builder.end_object ();
           builder.end_object ();
        }
        builder.end_array ();

        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        generator.pretty = true;
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        string current_contents = generator.to_data (null);
        try {
                file.replace_contents (current_contents.data, null, false,
                                       GLib.FileCreateFlags.NONE, null, null);

                print ("saved: %s\n", file.get_path ());
        }
        catch (GLib.Error err) {
            error ("%s\n", err.message);
        }
    }

    private void action_save_as (SimpleAction action, Variant? parameter) {
        var save_dialog = new Gtk.FileChooserNative ("Save canvas",
                                                     this as Gtk.Window,
                                                     Gtk.FileChooserAction.SAVE,
                                                     "Save", "Cancel");
        save_dialog.set_do_overwrite_confirmation (true);
        add_filters (save_dialog);
        save_dialog.set_modal (true);
        if (file != null) {
            try {
                (save_dialog as Gtk.FileChooser).set_file (file);
            }
            catch (GLib.Error error) {
                print ("%s\n", error.message);
            }
        }
        save_dialog.response.connect (save_as_response_cb);
        save_dialog.show ();
    }

    private void add_filters (Gtk.FileChooser chooser) {
        Gtk.FileFilter filter = new Gtk.FileFilter ();
        filter.add_pattern ("*.akira");
        filter.set_filter_name ("Akira files");
        chooser.add_filter(filter);
        filter = new Gtk.FileFilter ();
        filter.add_pattern ("*");
        filter.set_filter_name ("All files");
        chooser.add_filter(filter);
    }


    private void action_show_pixel_grid () {
        warning ("show pixel grid");
    }

    private void action_show_ui_grid () {
        warning ("show UI grid");
    }

    private void action_preferences () {
        var settings_dialog = new Akira.Widgets.SettingsDialog ();
        settings_dialog.transient_for = window;
        settings_dialog.show_all ();
        settings_dialog.present ();
    }

    private void action_export () {
        warning ("export");
    }

    private void action_zoom_in () {
        window.headerbar.zoom.zoom_in ();
    }

    private void action_zoom_out () {
        window.headerbar.zoom.zoom_out ();
    }

    private void action_zoom_reset () {
        window.headerbar.zoom.zoom_reset ();
    }

    private void action_rect_tool () {
        window.main_window.main_canvas.canvas.edit_mode = Akira.Lib.Canvas.EditMode.MODE_INSERT;
        window.main_window.main_canvas.canvas.insert_type = Akira.Lib.Canvas.InsertType.RECT;
    }

    private void action_selection_tool () {
        window.main_window.main_canvas.canvas.edit_mode = Akira.Lib.Canvas.EditMode.MODE_SELECTION;
        window.main_window.main_canvas.canvas.insert_type = null;
    }

    private void action_delete () {
        window.main_window.main_canvas.canvas.delete_selected ();
    }

    private void action_ellipse_tool () {
        window.main_window.main_canvas.canvas.edit_mode = Akira.Lib.Canvas.EditMode.MODE_INSERT;
        window.main_window.main_canvas.canvas.insert_type = Akira.Lib.Canvas.InsertType.ELLIPSE;
    }

    private void action_text_tool () {
        window.main_window.main_canvas.canvas.edit_mode = Akira.Lib.Canvas.EditMode.MODE_INSERT;
        window.main_window.main_canvas.canvas.insert_type = Akira.Lib.Canvas.InsertType.TEXT;
    }

    public static void action_from_group (string action_name, ActionGroup? action_group) {
        action_group.activate_action (action_name, null);
    }
}
