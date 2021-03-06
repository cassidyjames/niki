/*
* Copyright (c) {2019} torikulhabib (https://github.com/torikulhabib)
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
* Authored by: torikulhabib <torik.habib@Gmail.com>
*/

namespace niki {
    public class SeekBar : Gtk.Grid {
        public PreviewPopover? preview_popover {get; set;}
        private Gtk.Scale scale;
        private Gee.HashMap<string, string> string_lyric;
        private Lyric? lyric;
        private string current_lyric;
        private string next_lyric_end;
        private string duration_string;
        public string duration_n_progress;

        private double _playback_duration;
        public double playback_duration {
            get {
                return _playback_duration;
            }
            set {
                double duration = value;
                if (duration < 0.0) {
                    duration = 0.0;
                }
                _playback_duration = duration;
                duration_string = seconds_to_time ((int) duration);

            }
        }
        private double _playback_progress;
        public double playback_progress {
            get {
                return _playback_progress;
            }
            set {
                double progress = value;
                if (progress < 0.0) {
                    progress = 0.0;
                } else if (progress > 1.0) {
                    progress = 1.0;
                }
                _playback_progress = progress;
                duration_n_progress = seconds_to_time ((int) (progress * playback_duration)) +" / " + duration_string;
                scale.set_value (progress);
            }
        }

        public SeekBar (PlayerPage playerpage) {
            get_style_context ().add_class ("ground_action_button");
            get_style_context ().add_class ("seek_bar");
            get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0.0, 1.0, 0.01);
            scale.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            scale.get_style_context ().add_class ("label");
            scale.vexpand = scale.hexpand = true;
            scale.draw_value = false;
            preview_popover = new PreviewPopover ();
            preview_popover.relative_to = scale;

            playerpage.playback.notify["progress"].connect (() => {
                playback_progress = playerpage.playback.progress;
                start (playerpage);
            });
            playerpage.playback.notify["duration"].connect (() => {
                scale.set_range (0.0, 1.0);
                playback_duration = playerpage.playback.duration;
            });

            scale.enter_notify_event.connect (() => {
                if (window.is_active) {
                    cursor_hand_mode (0);
                    preview_popover.schedule_show ();
                }
                return false;
            });
            scale.leave_notify_event.connect (() => {
                cursor_hand_mode (2);
                preview_popover.schedule_hide ();
                return false;
            });
            scale.motion_notify_event.connect ((event) => {
                cursor_hand_mode (0);
                preview_popover.update_pointing ((int) event.x);
                preview_popover.set_preview_progress (event.x / ((double) event.window.get_width ()), !playerpage.playback.playing);
                preview_popover.label_progress.label = " " + seconds_to_time ((int) (event.x / ((double) event.window.get_width ()) * playerpage.playback.duration)) + " ";
                return false;
            });

            scale.change_value.connect ((scroll, new_value) => {
                if (scroll == Gtk.ScrollType.JUMP) {
                    if (NikiApp.settings.get_int ("speed-playing") != 4) {
                        playerpage.playback.pipeline.set_state (Gst.State.PAUSED);
                        playerpage.playback.progress = new_value;
                        if (playerpage.playback.playing) {
                            playerpage.playback.pipeline.set_state (Gst.State.PLAYING);
                        }
                    } else {
                        playerpage.playback.progress = new_value;
                    }
                }
                return false;
            });
            margin = 0;
            margin_end = margin_start = 5;
            hexpand = true;
            add (scale);
            show_all ();
        }

        public Lyric file_lyric (string liric_file) {
            return new LyricParser ().parse (File.new_for_uri (liric_file));
        }

        public void on_lyric_update (Lyric lyric) {
            this.lyric = lyric;
            string_lyric = new Gee.HashMap<string, string> ();
            lyric.foreach ((item) => {
                string_lyric[item.key.to_string ()] = item.value;
                return true;
            });
        }
        public string get_liric_now () {
            return current_lyric;
        }
        public string get_liric_next () {
            return next_lyric_end;
        }

        public void start (PlayerPage playerpage) {
            if (playerpage.playback.playing) {
                if (NikiApp.settings.get_boolean("lyric-available") && NikiApp.settings.get_boolean("audio-video")) {
                    var seconds_time = ((int64)(playerpage.playback.get_position () * 1000000));
                    current_lyric = " " + string_lyric[lyric.get_lyric_timestamp (seconds_time).to_string ()] + " ";
                    string next_lyric = " " + string_lyric[lyric.get_lyric_timestamp (seconds_time, false).to_string ()] + " ";
                    next_lyric_end = next_lyric.contains (current_lyric)? "" : next_lyric;
                }
            }
        }
    }
}
