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
* Authored by: Giacomo "giacomoalbe" Alberini <giacomoalbe@gmail.com>
*/

public class Akira.Models.FillsItemModel : GLib.Object {
    public string color {
        owned get {
            var rgba = item.fill_color_rgba;
            debug ("fills2: get color int %u", rgba);
            string s = "rgba(%u,%u,%u,%f)"
            .printf(rgba >> 24 & 0xFF,
                    rgba >> 16 & 0xFF,
                    rgba >>  8 & 0xFF,
                    (double)(rgba >>  0 & 0xFF) / 255);
            debug ("fills2: get color %s", s);
            var result = "#%02x%02x%02x"
            .printf((int)(Math.round(rgba >> 24 & 0xFF)),
                    (int)(Math.round(rgba >> 16 & 0xFF)),
                    (int)(Math.round(rgba >>  8 & 0xFF)));
            debug ("fills: get color %s", result);
            return result;
        } set {
            debug ("fills: set color: %s", value);
            var newRGBA = Gdk.RGBA ();
            newRGBA.parse (value);
            debug ("fills2: color choosed: %f,%f,%f,%f", newRGBA.red, newRGBA.green, newRGBA.blue, newRGBA.alpha);
            debug ("fills2: color choosed real alpha: %f,%f,%f,%f", newRGBA.red, newRGBA.green, newRGBA.blue, alpha);
            uint rgba = (uint)Math.round(newRGBA.red * 255);
            rgba = (rgba << 8) + (uint)Math.round(newRGBA.green * 255);
            rgba = (rgba << 8) + (uint)Math.round(newRGBA.blue * 255);
            rgba = (rgba << 8) + (uint)Math.round(alpha);
            debug ("fills2: set hex to int %u\n", rgba);
            item.fill_color_rgba = rgba;
        }
    }
    public double alpha {
        get {
            var get_alpha = item.fill_color_rgba & 0xFF;
            debug ("fills2: get alpha %u", get_alpha);
            return get_alpha;
        }
        set {
            var rgba = item.fill_color_rgba;
            debug ("fills: rgba: %f", rgba);
            debug ("fills: new opacity %f", value);
            debug ("fills: color without alpha %f", (rgba & 0xFFFFFF00));
            var new_rgba = (rgba & 0xFFFFFF00) + (uint)(value * 255);
            debug ("fills: new color with alpha %f", new_rgba);
            item.fill_color_rgba = new_rgba;
        }
    }
    public bool hidden { get; set; }
    public Akira.Utils.BlendingMode blending_mode { get; set; }
    public Akira.Models.FillsListModel list_model { get; set; }
    public Goo.CanvasItemSimple item { get; construct; }

    public FillsItemModel(Goo.CanvasItemSimple item_simple,
                           bool hidden,
                           Akira.Utils.BlendingMode blending_mode,
                           Akira.Models.FillsListModel list_model) {
        Object (
            hidden: hidden,
            blending_mode: blending_mode,
            list_model: list_model,
            item: item_simple
        );
    }

    public string to_string () {
        return "Color: %s\nAlpha: %f\nHidden: %s\nBlendingMode: %s".printf (
            color, alpha, (hidden ? "1" : "0"), blending_mode.to_string ());
    }
}
