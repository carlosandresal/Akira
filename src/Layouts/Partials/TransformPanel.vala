/*
* Copyright (c) 2019 Alecaddd (http://alecaddd.com)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Ana Gelez <ana@gelez.xyz>
* Edited by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/
public class Akira.Layouts.Partials.TransformPanel : Gtk.Grid {
    // Should probably be associated with the currently selected object
    // once the canvas is working
    public weak Akira.Window window { get; construct; }
    public bool size_lock { get; set; default = false; }
    private Akira.Partials.LinkedInput x;
    private Akira.Partials.LinkedInput y;
    private Akira.Partials.LinkedInput width;
    private Akira.Partials.LinkedInput height;
    private Akira.Partials.LinkedInput rotation;
    private Akira.Partials.LinkedInput opacity_entry;

    public TransformPanel (Akira.Window main_window) {
        Object (
            window: main_window,
            orientation: Gtk.Orientation.HORIZONTAL
        );
    }


    private Goo.CanvasItem _item;

    public Goo.CanvasItem item {
        get {
            return _item;
        } set {
            if (_item != null) {
                _item.notify.disconnect(item_changed);
            }
            _item = value;
            bool has_item = _item != null;
            x.enabled = has_item;
            y.enabled = has_item;
            height.enabled = has_item;
            width.enabled = has_item;
            rotation.enabled = has_item;

            _item.notify.connect(item_changed);
            update_fields ();
        }
    }

    private double get_item_rotation () {
        return 0;
        var matrix = Cairo.Matrix.identity ();
        if (item == null) {
            debug ("item is null");
            return 0;
        }
        item.get_transform (out matrix);
        print_matrix(matrix);
        var xx = matrix.xx;
        double item_rotation = Math.acos(xx);
        item_rotation = item_rotation * (180 / Math.PI);
        debug ("item rotation: %f", item_rotation);
        double item_rotation_sin = Math.asin(matrix.yx);
        debug ("item rotation sin: %f", item_rotation_sin * 180/Math.PI);

        if (item_rotation_sin < 0) {
            item_rotation += 180;
        }
        debug ("item rotation: %f", item_rotation);
        return item_rotation;
    }

    private void item_changed (Object object, ParamSpec spec) {
        debug ("item changed, param: %s", spec.name);
        update_fields ();
    }

    private void update_fields () {
        double item_x, item_y, item_width, item_height/*, alpha*/;
        item.get ("x", out item_x, "y", out item_y, "width", out item_width, "height", out item_height/*, "alpha", out alpha*/);
        window.main_window.main_canvas.canvas.convert_from_item_space (item, ref item_x, ref item_y);
        window.main_window.main_canvas.canvas.update_decorations (item);

        x.value = item_x;
        y.value = item_y;
        width.value = item_width;
        height.value = item_height;
        rotation.value = get_item_rotation();
        //opacity_entry.value = alpha * 100;
    }

    double size_ratio = 1.0;

    construct {
        border_width = 12;
        row_spacing = 6;
        column_spacing = 6;
        hexpand = true;

        x = new Akira.Partials.LinkedInput (_("X"), _("Horizontal position"));
        x.notify["value"].connect (x_notify_value);

        y = new Akira.Partials.LinkedInput (_("Y"), _("Vertical position"));
        y.notify["value"].connect (y_notify_value);
        width = new Akira.Partials.LinkedInput (_("W"), _("Width"));
        height = new Akira.Partials.LinkedInput (_("H"), _("Height"));
        width.notify["value"].connect (width_notify_value);
        height.notify["value"].connect (height_notify_value);

        var lock_changes = new Gtk.Button.from_icon_name ("changes-allow-symbolic");
        lock_changes.can_focus = false;
        lock_changes.tooltip_text = _("Lock Ratio");
        lock_changes.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        lock_changes.get_style_context ().add_class ("button-rounded");
        lock_changes.get_style_context ().add_class ("label-colors");
        bind_property (
            "size-lock", lock_changes, "image", BindingFlags.SYNC_CREATE,
            (binding, val, ref res) => {
                var icon = val.get_boolean () ? "changes-prevent-symbolic" : "changes-allow-symbolic";
                var image = new Gtk.Image.from_icon_name (icon, Gtk.IconSize.BUTTON);
                res = image;
                return true;
            });
        lock_changes.clicked.connect (() => {
            size_lock = !size_lock;
        });

        rotation = new Akira.Partials.LinkedInput (_("R"), _("Rotation degrees"), "°");
        rotation.notify["value"].connect (rotation_notify_value);

        var hflip_button = new Gtk.Button ();
        hflip_button.add (new Akira.Partials.ButtonImage ("object-flip-horizontal"));
        hflip_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        hflip_button.get_style_context ().add_class ("button-rounded");
        hflip_button.hexpand = false;
        hflip_button.halign = Gtk.Align.CENTER;
        hflip_button.valign = Gtk.Align.CENTER;
        hflip_button.can_focus = false;
        hflip_button.tooltip_markup = Granite.markup_accel_tooltip ({"<Ctrl><Shift>bracketleft"}, _("Flip Horizontally"));

        var vflip_button = new Gtk.Button ();
        vflip_button.add (new Akira.Partials.ButtonImage ("object-flip-vertical"));
        vflip_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        vflip_button.get_style_context ().add_class ("button-rounded");
        vflip_button.hexpand = false;
        vflip_button.halign = Gtk.Align.CENTER;
        vflip_button.valign = Gtk.Align.CENTER;
        vflip_button.can_focus = false;
        vflip_button.tooltip_markup = Granite.markup_accel_tooltip ({"<Ctrl><Shift>bracketright"}, _("Flip Vertically"));

        var align_grid = new Gtk.Grid ();
        align_grid.hexpand = true;
        align_grid.column_homogeneous = true;
        align_grid.attach (hflip_button, 0, 0, 1, 1);
        align_grid.attach (vflip_button, 1, 0, 1, 1);

        var opacity = new Gtk.Adjustment (100.0, 0, 100.0, 0, 0, 0);
        var scale = new Gtk.Scale (Gtk.Orientation.HORIZONTAL, opacity);
        scale.hexpand = true;
        scale.draw_value = false;
        scale.sensitive = true;
        scale.round_digits = 1;
        scale.margin_end = 30;
        var opacity_entry = new Akira.Partials.InputField (
            Akira.Partials.InputField.Unit.PERCENTAGE, 7, true, true);
        opacity_entry.entry.text = (opacity.get_value ()).to_string ();
        opacity_entry.entry.bind_property (
            "text", opacity, "value",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE,
            (binding, srcval, ref targetval) => {
                double src = double.parse (srcval.dup_string ());
                if (src > 100 || src < 0) {
                    opacity_entry.entry.text = (opacity.get_value ()).to_string ();
                    return false;
                }
                targetval.set_double (src);
                return true;
            }, (binding, srcval, ref targetval) => {
                double src = (double) srcval;
                targetval.set_string (("%0.1f").printf (src));
                return true;
            }
        );
        opacity_entry.notify["value"].connect (opacity_notify_value);
        opacity_entry.entry.hexpand = false;
        opacity_entry.entry.width_request = 64;

        var opacity_grid = new Gtk.Grid ();
        opacity_grid.hexpand = true;
        opacity_grid.attach (scale, 0, 0, 1);
        opacity_grid.attach (opacity_entry, 1, 0, 1);

        attach (group_title (_("Position")), 0, 0, 3);
        attach (x, 0, 1, 1);
        attach (y, 2, 1, 1);

        attach (new Akira.Partials.PanelSeparator (), 0, 2, 3);

        attach (group_title (_("Size")), 0, 3, 3);
        attach (width, 0, 4, 1);
        attach (lock_changes, 1, 4, 1);
        attach (height, 2, 4, 1);

        attach (new Akira.Partials.PanelSeparator (), 0, 5, 3);

        attach (group_title (_("Transform")), 0, 6, 3);
        attach (rotation, 0, 7, 1);
        attach (align_grid, 2, 7, 1);

        attach (new Akira.Partials.PanelSeparator (), 0, 8, 3);

        attach (group_title (_("Opacity")), 0, 9, 3);
        attach (opacity_grid, 0, 10, 3);
    }

    public void opacity_notify_value () {
        item.set("alpha", opacity_entry.value / 100);
    }

    public void y_notify_value () {
        double item_x = x.value;
        double item_y = y.value;
        window.main_window.main_canvas.canvas.convert_to_item_space(item, ref item_x, ref item_y);
        item.set("y", item_y);
    }

    public void x_notify_value () {
        double item_x = x.value;
        double item_y = y.value;
        window.main_window.main_canvas.canvas.convert_to_item_space(item, ref item_x, ref item_y);
        item.set("x", item_x);
    }

    public void rotation_notify_value () {
        debug ("rotate");
        double item_x, item_y, item_width, item_height;
        item.get ("x", out item_x, "y", out item_y, "width", out item_width, "height", out item_height);
        double? item_rotation = item.get_data<double?>("rotation");
        debug ("actual rotation: %f", item_rotation);
        var total_rotation = rotation.value;
        item_rotation = total_rotation - item_rotation;
        debug ("rotation correction: %f", item_rotation);
        debug ("center: (%f,%f)", item_x + item_width/2, item_y + item_height/2);
        item.rotate(item_rotation, item_x + item_width/2, item_y + item_height/2);
        item.set_data<double?>("rotation", total_rotation);
    }

    private void print_matrix (Cairo.Matrix matrix) {
        debug ("x0: %f, xx: %f, xy: %f", matrix.x0, matrix.xx, matrix.xy);
        debug ("y0: %f, yx: %f, yy: %f", matrix.y0, matrix.yx, matrix.yy);
    }

    public void height_notify_value () {
        item.set("height", height.value);
        if (size_lock) {
            width.value = height.value * size_ratio;
        } else {
            size_ratio = width.value / height.value;
        }
    }

    public void width_notify_value () {
        item.set("width", width.value);
        if (size_lock) {
            height.value = width.value / size_ratio;
        } else {
            size_ratio = width.value / height.value;
        }
    }

    private Gtk.Label group_title (string title) {
        var title_label = new Gtk.Label ("%s".printf (title));
        title_label.get_style_context ().add_class ("group-title");
        title_label.halign = Gtk.Align.START;
        title_label.hexpand = true;
        title_label.margin_bottom = 2;
        return title_label;
    }
}
