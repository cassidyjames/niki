/*-
 * Copyright (c) 2016 elementary LLC. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Library General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

[DBus (name = "org.freedesktop.ScreenSaver")]
public interface ScreenSaverIface : Object {
    public abstract uint32 Inhibit (string app_name, string reason) throws Error;
    public abstract void UnInhibit (uint32 cookie) throws Error;
    public abstract void SimulateUserActivity () throws Error;
}

namespace niki {
    public class Inhibitor :  Object {
        private uint32? inhibit_cookie = null;
        private ScreenSaverIface? screensaver_iface = null;
        private bool inhibited = false;

        private static Inhibitor _instance = null;
        public static Inhibitor instance {
            get {
                if (_instance == null) {
                    _instance = new Inhibitor ();
                }
                return _instance;
            }
        }

        construct {
            try {
                screensaver_iface = Bus.get_proxy_sync (BusType.SESSION, "org.freedesktop.ScreenSaver", "/ScreenSaver", DBusProxyFlags.NONE);
            } catch (Error e) {
                warning ("Could not start screensaver interface: %s", e.message);
            }
        }

        public void inhibit () {
            if (screensaver_iface != null && !inhibited) {
                try {
                    inhibited = true;
                    inhibit_cookie = screensaver_iface.Inhibit (NikiApp.instance.application_id, "Playing movie");
                    simulate_activity ();
                } catch (Error e) {
                    warning ("Could not inhibit screen: %s", e.message);
                }
            }
        }

        public void uninhibit () {
            if (screensaver_iface != null && inhibited) {
                try {
                    inhibited = false;
                    screensaver_iface.UnInhibit (inhibit_cookie);
                } catch (Error e) {
                    warning ("Could not uninhibit screen: %s", e.message);
                }
            }
        }

        private bool simulator_started = false;
        private void simulate_activity () {
            if (simulator_started){
                return;
            }
            simulator_started = true;
            Timeout.add_full (Priority.LOW, 120000, ()=> {
                if (inhibited) {
                    try {
                        screensaver_iface.SimulateUserActivity ();
                    } catch (Error e) {
                        warning ("Could not simulate user activity: %s", e.message);
                    }
                } else {
                    simulator_started = false;
                }
                return inhibited;
            });
        }
    }
}
